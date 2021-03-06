require "blade"
require "blade/sauce_labs_plugin/version"
require "blade/sauce_labs_plugin/cli"

require "active_support/core_ext/string/inflections"

module Blade::SauceLabsPlugin
  extend self
  include Blade::Component

  autoload :Client, "blade/sauce_labs_plugin/client"
  autoload :Tunnel, "blade/sauce_labs_plugin/tunnel"
  autoload :WebDriver, "blade/sauce_labs_plugin/web_driver"
  autoload :Job, "blade/sauce_labs_plugin/job"
  autoload :JobManager, "blade/sauce_labs_plugin/job_manager"
  autoload :SessionManager, "blade/sauce_labs_plugin/session_manager"

  def start
    if Blade.config.interface == :ci
      tunnel.start do
        session_manager.start
        job_manager.start
      end
    end
  end

  def stop
    tunnel.stop
    job_manager.stop
  end

  # Ensure the tunnel is closed
  at_exit { tunnel.stop }

  def tunnel
    Tunnel
  end

  def client
    Client
  end

  def session_manager
    SessionManager
  end

  def job_manager
    JobManager
  end

  def config
    Blade.config.plugins.sauce_labs
  end

  def username
    ENV["SAUCE_USERNAME"] || config.username
  end

  def access_key
    ENV["SAUCE_ACCESS_KEY"] || config.access_key
  end

  def tunnel_timeout
    (ENV["SAUCE_TUNNEL_TIMEOUT"] || config.tunnel_timeout || 60).to_i
  end

  def debug(message)
    if debug?
      STDERR.puts message
    end
  end

  def debug?
    config.debug == true
  end
end
