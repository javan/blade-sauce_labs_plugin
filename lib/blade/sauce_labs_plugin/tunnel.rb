require "childprocess"
require "securerandom"

module Blade::SauceLabsPlugin::Tunnel
  extend self

  extend Forwardable
  def_delegators Blade::SauceLabsPlugin, :username, :access_key, :config, :debug, :debug?

  attr_reader :identifier, :process

  def start
    @identifier = SecureRandom.hex(10)
    @process = create_child_process

    timer = EM::PeriodicTimer.new(1) do
      if ready_file_exists?
        timer.cancel
        yield
      end
    end
  end

  def stop
    begin
      process.poll_for_exit(10)
    rescue ChildProcess::TimeoutError
      process.stop
    rescue
      nil
    end
  end

  private
    def create_child_process
      ChildProcess.build(tunnel_command, *tunnel_args).tap do |process|
        process.leader = true
        process.io.inherit! if debug?
        process.start
        debug process.inspect
      end
    end

    def tunnel_command
      Pathname.new(File.dirname(__FILE__)).join("../../../support/sc-#{os}/bin/sc").to_s
    end

    def tunnel_args
      ["--user", username, "--api-key", access_key, "--tunnel-identifier", identifier, "--readyfile", ready_file_path]
    end

    def ready_file_path
      Blade.tmp_path.join("sauce_tunnel_#{identifier}_ready").to_s
    end

    def ready_file_exists?
      File.exists?(ready_file_path)
    end

    def remove_ready_file
      File.unlink(ready_file_path) if ready_file_exists?
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
