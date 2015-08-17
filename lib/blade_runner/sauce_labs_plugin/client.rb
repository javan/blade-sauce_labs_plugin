require "faraday"
require "json"

module BladeRunner::SauceLabsPlugin::Client
  extend self

  extend Forwardable
  def_delegators BladeRunner::SauceLabsPlugin, :config, :username, :access_key

  def request(method, path, params = {})
    connection.send(method) do |req|
      req.url path
      req.headers["Content-Type"] = "application/json"
      req.body = params.to_json
    end
  end

  def platforms
    config.browsers.flat_map do |browser|
      platforms_for_browser(browser)
    end
  end

  def platforms_for_browser(browser)
    long_name = find_browser_long_name(browser[:name])
    platforms = available_platforms_by_browser[long_name]
    platform_versions = platforms.flat_map { |os, details| details[:versions] }.uniq.sort.reverse

    versions = case
      when browser[:latest_versions]
        platform_versions.first(browser[:latest_versions])
      when browser[:version]
        Array(browser[:version]).map(&:to_f)
      else
        platform_versions.first(1)
      end

    if browser[:os]
      Array(browser[:os]).flat_map do |browser_os|
        versions.map do |version|
          os = platforms.keys.detect { |os| os =~ Regexp.new(browser_os, Regexp::IGNORECASE) }
          platforms[os][:api][version].first
        end
      end
    else
      versions.map do |version|
        os = platforms.detect { |os, details| details[:api][version].any? }.first
        platforms[os][:api][version].first
      end
    end
  end

  def find_browser_long_name(name)
    available_platforms_by_browser.keys.detect do |long_name|
      long_name =~ Regexp.new(name, Regexp::IGNORECASE)
    end
  end

  def available_platforms_by_browser
    @available_platforms_by_browser ||= {}.tap do |by_browser|
      available_platforms.group_by { |p| p[:api_name] }.each do |api_name, platforms|
        long_name = platforms.first[:long_name]
        by_browser[long_name] = {}

        platforms.group_by { |p| p[:os].split(" ").first }.each do |os, platforms|
          by_browser[long_name][os] = {}
          by_browser[long_name][os][:versions] = []
          by_browser[long_name][os][:api] = {}

          versions = platforms.map { |p| p[:short_version].to_f }.uniq.sort.reverse

          versions.each do |version|
            by_browser[long_name][os][:versions] << version

            by_browser[long_name][os][:api][version] = platforms.map do |platform|
              if platform[:short_version].to_f == version
                platform.values_at(:os, :api_name, :short_version)
              end
            end.compact
          end
        end
      end
    end
  end

  private
    def connection
      @connnection ||= Faraday.new("https://#{username}:#{access_key}@saucelabs.com/")
    end

    def available_platforms
      @available_platforms ||= JSON.parse(connection.get("/rest/v1/info/platforms/webdriver").body).map(&:symbolize_keys)
    end
end
