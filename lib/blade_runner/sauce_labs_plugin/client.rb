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
    @platforms ||= [].tap do |platforms|
      config.browsers.each do |browser|
        browser["platforms"].each do |platform|
          for_browser = available_platforms.select { |p| p["long_name"] == browser["name"] }
          version = for_browser.map { |p| p["short_version"].to_f }.sort.uniq.last
          for_os = for_browser.select { |p| p["os"] =~ Regexp.new(platform) && p["short_version"].to_f == version }

          if match = for_os.sort_by { |p| p["os"] }.last
            platforms << [match["os"], match["api_name"], match["short_version"]]
          end
        end
      end
    end
  end

  def available_platforms_by_browser
    {}.tap do |list|
      available_platforms.group_by { |p| p["api_name"] }.each do |api_name, platforms|
        name = platforms.map { |p| p["long_name"] }.first
        list[name] = { "aliases" => [], "versions" => {} }

        unless api_name.downcase == name.downcase
          list[name]["aliases"] << api_name
        end

        if name =~ /\s/
          list[name]["aliases"] << name.split(/\s/).map { |part| part[0] }.join
        end

        platforms.group_by { |p| p["os"].split(" ").first }.each do |os, platforms|
          versions = platforms.sort_by { |p| p["short_version"].to_f }.reverse.map { |p| p["short_version"] }.uniq
          list[name]["versions"][os] = versions
        end
      end
    end.with_indifferent_access
  end

  private
    def connection
      @connnection ||= Faraday.new("https://#{username}:#{access_key}@saucelabs.com/")
    end

    def available_platforms
      @available_platforms ||= JSON.parse(connection.get("/rest/v1/info/platforms/webdriver").body)
    end
end
