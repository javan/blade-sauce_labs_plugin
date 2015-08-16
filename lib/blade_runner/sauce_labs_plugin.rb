require "blade_runner/sauce_labs_plugin/version"
require "blade_runner/sauce_labs_plugin/cli"

require "active_support/core_ext/string/inflections"

module BladeRunner::SauceLabsPlugin
  extend self
  include BladeRunner::Component

  autoload :Client, "blade_runner/sauce_labs_plugin/client"
  autoload :Tunnel, "blade_runner/sauce_labs_plugin/tunnel"

  def start
    if BladeRunner.config.interface == :ci
      Tunnel.start
      BladeRunner.config.expected_sessions = Client.platforms.size
      Client.request(:post, "rest/v1/#{username}/js-tests", test_params)
    end
  end

  def stop
    Tunnel.stop
  end

  def config
    @config ||= if BladeRunner.plugins
      BladeRunner.plugins.sauce_labs.config
    else
      OpenStruct.new
    end
  end

  def username
    config.username || ENV["SAUCE_USERNAME"]
  end

  def access_key
    config.access_key || ENV["SAUCE_ACCESS_KEY"]
  end

  private
    def test_params
      { url: BladeRunner.url, platforms: Client.platforms, framework: BladeRunner.config.framework }.merge(default_test_config).merge(test_config)
    end

    def default_test_config
      { build: rev, max_duration: 200 }
    end

    def rev
      @rev ||= `git rev-parse HEAD`.chomp
    end

    def test_config
      if config.test_config
        {}.tap do |result|
          config.test_config.each do |key, value|
            result[key.to_s.camelize(:lower)] = value
          end
        end
      else
        {}
      end
    end
end
