require "blade"
require "blade/sauce_labs_plugin/version"
require "blade/sauce_labs_plugin/cli"

require "active_support/core_ext/string/inflections"

module Blade::SauceLabsPlugin
  extend self
  include Blade::Component

  autoload :Client, "blade/sauce_labs_plugin/client"
  autoload :Tunnel, "blade/sauce_labs_plugin/tunnel"

  def start
    if Blade.config.interface == :ci
      Tunnel.start do
        Blade.config.expected_sessions = Client.platforms.size
        Client.request(:post, "rest/v1/#{username}/js-tests", test_params)
      end
    end
  end

  def stop
    Tunnel.stop
  end

  # Ensure the tunnel is closed
  at_exit { stop }

  def config
    Blade.plugins.sauce_labs.config
  end

  def username
    config.username || ENV["SAUCE_USERNAME"]
  end

  def access_key
    config.access_key || ENV["SAUCE_ACCESS_KEY"]
  end

  def log(message)
    if log?
      STDERR.puts message
    end
  end

  def log?
    config.log == true
  end

  private
    def test_params
      { url: Blade.url, platforms: Client.platforms, framework: Blade.config.framework, tunnelIdentifier: Tunnel.identifier }.merge(default_test_config).merge(test_config)
    end

    def default_test_config
      { build: rev, maxDuration: 300 }
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
