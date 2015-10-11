require "securerandom"
require "shellwords"

module Blade::SauceLabsPlugin::Tunnel
  extend self

  extend Forwardable
  def_delegators Blade::SauceLabsPlugin, :username, :access_key

  attr_reader :identifier, :ready_file, :pid

  def start
    @identifier = SecureRandom.hex(10)
    @ready_file = Blade.tmp_path.join("sauce_tunnel_#{identifier}_ready").to_s
    @pid = EM::DeferrableChildProcess.open(command).get_pid

    timer = EM::PeriodicTimer.new(1) do
      if File.exists?(ready_file)
        File.unlink(ready_file)
        timer.cancel
        yield
      end
    end
  end

  def stop
    Process.kill("INT", pid) rescue nil
  end

  private
    def command
      [tunnel_command, tunnel_args].join(" ")
    end

    def tunnel_command
      Pathname.new(File.dirname(__FILE__)).join("../../../support/sc-#{os}/bin/sc").to_s
    end

    def tunnel_args
      ["--user", username, "--api-key", access_key, "--tunnel-identifier", identifier, "--readyfile", ready_file].shelljoin
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
