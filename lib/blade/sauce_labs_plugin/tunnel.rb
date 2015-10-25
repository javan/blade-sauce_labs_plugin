require "childprocess"
require "securerandom"
require "shellwords"

module Blade::SauceLabsPlugin::Tunnel
  extend self

  extend Forwardable
  def_delegators Blade::SauceLabsPlugin, :username, :access_key, :config, :log, :log?

  attr_reader :identifier, :pid

  def start
    @identifier = SecureRandom.hex(10)
    log "Tunnel command: `#{tunnel_command}'"
    log "Tunnel command executable? #{Pathname.new(tunnel_command).executable?}"
    log "Command: `#{command}'"
    log "PWD: #{`pwd`.chomp}"
    log "TMP: #{`ls -al #{Blade.tmp_path.to_s}`.chomp}"

    @process = ChildProcess.build(tunnel_command, *tunnel_args)
    @process.leader = true
    @process.io.inherit! if log?
    @process.start

    log @process.inspect

    timer = EM::PeriodicTimer.new(1) do
      if ready_file_exists?
        log "Ready file present"
        timer.cancel
        yield
      else
        log "Ready file not preset yet"
      end
    end
  end

  def stop
    begin
      @process.poll_for_exit(10)
    rescue ChildProcess::TimeoutError
      @process.stop
    rescue
      nil
    end
  end

  private
    def command
      [tunnel_command, tunnel_args].compact.join(" ")
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
