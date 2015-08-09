require "blade_runner/sauce_labs_plugin/version"

require "faraday"
require "childprocess"
require "json"

module BladeRunner::SauceLabsPlugin
  include BladeRunner::Component
  extend self

  attr_reader :config, :username, :access_key, :max_duration

  @config = BladeRunner.plugins.sauce_labs.config
  @username = config.username || ENV["SAUCE_USERNAME"]
  @access_key = config.access_key || ENV["SAUCE_ACCESS_KEY"]
  @max_duration = config.max_duration || 200

  def start
    start_tunnel
    BladeRunner.config.expected_sessions = platforms.size
    request(:post, "rest/v1/#{username}/js-tests", test_params)
  end

  def stop
    stop_tunnel
  end

  private
    def request(method, path, params = {})
      connection.send(method) do |req|
        req.url path
        req.headers["Content-Type"] = "application/json"
        req.body = params.to_json
      end
    end

    def test_params
      { url: BladeRunner.url, build: rev, platforms: platforms, framework: BladeRunner.config.framework, max_duration: max_duration }
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

    def rev
      @rev ||= `git rev-parse HEAD`.chomp
    end

    def connection
      @connnection ||= Faraday.new("https://#{username}:#{access_key}@saucelabs.com/")
    end

    def available_platforms
      @available_platforms ||= JSON.parse(connection.get("/rest/v1/info/platforms/webdriver").body)
    end

    def start_tunnel
      return if @process
      cmd = Pathname.new(File.dirname(__FILE__)).join("../../support/sc-#{os}/bin/sc").to_s
      @process = ChildProcess.build(cmd, "--user", username, "--api-key", access_key)
      reader, writer = IO.pipe
      @process.io.stdout = @process.io.stderr = writer
      @process.start

      output = ""
      while line = reader.gets
        output << line
        case line
        when /Sauce Connect is up, you may start your tests/
          break
        when /Goodbye/
          STDERR.puts output
          raise "Sauce Connect tunnel connection error"
        end
      end

    ensure
      writer.close if writer
      reader.close if reader
    end

    def stop_tunnel
      return unless @process
      @process.stop
    end

    def os
      @os ||=
        case RUBY_PLATFORM.downcase
        when /linux/   then :linux
        when /darwin/  then :osx
        when /windows/ then :windows
        end
    end
end
