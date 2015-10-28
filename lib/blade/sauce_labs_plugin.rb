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

  def debug(message)
    if debug?
      STDERR.puts message
    end
  end

  def debug?
    config.debug == true
  end

  private
    def test_params
      camelize_keys(combined_test_config)
    end

    def combined_test_config
      default_test_config.merge(env_test_config).merge(test_config)
    end

    def test_config
      config.test_config || {}
    end

    def default_test_config
      {
        url: Blade.url,
        platforms: Client.platforms,
        framework: Blade.config.framework,
        tunnel_identifier: Tunnel.identifier,
        max_duration: 300,
        name: "Blade Runner CI",
        build: default_build
      }
    end

    def env_test_config
      {}.tap do |config|
        if build = get_env_value(:build_number)
          config[:build] = build
        end

        tags = []

        [:commit, :repo_slug, :pull_request].each do |key|
          if tag = tag_from_env(key)
            tags << tag
          end
        end

        config[:tags] = tags if tags.any?
      end
    end

    def tag_from_env(key)
      if value = get_env_value(key)
        [key, value].join(":")
      end
    end

    def get_env_value(key)
      key = key.to_s.upcase
      ENV[key].presence || ENV["TRAVIS_#{key}"].presence
    end

    def default_build
      [rev, Time.now.utc.to_i].select(&:present?).join("-")
    end

    def rev
      @rev ||= `git rev-parse HEAD 2>/dev/null`.chomp
    end

    def camelize_keys(hash)
      {}.tap do |result|
        hash.each do |key, value|
          result[key.to_s.camelize(:lower)] = value
        end
      end
    end
end
