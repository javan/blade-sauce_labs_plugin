require "securerandom"
require "shellwords"

module Blade::SauceLabsPlugin::Tunnel
  extend self

  extend Forwardable
  def_delegators Blade::SauceLabsPlugin, :username, :access_key, :log

  attr_reader :identifier, :pid

  def start
    @identifier = SecureRandom.hex(10)
    log "Tunnel command: `#{tunnel_command}'"
    log "Tunnel command executable? #{Pathname.new(tunnel_command).executable?}"
    log "Command: `#{command}'"
    log "PWD: #{`pwd`.chomp}"
    log "TMP: #{`ls -al #{Blade.tmp_path.to_s}`.chomp}"

    @pid = EM::DeferrableChildProcess.open(command).get_pid
    log "Tunnel PID: #{@pid}"

    timer = EM::PeriodicTimer.new(1) do
      if ready_file_exists?
        log "Ready file present"
        timer.cancel
        yield
      else
        log "Ready file not preset yet"
        log `ps auxww | grep #{@pid} | grep -v grep`.chomp
      end
    end
  end

  def stop
    signal = ready_file_exists? ? "INT" : "KILL"
    remove_ready_file
    Process.kill(signal, pid) rescue nil
  end

  private
    def command
      [tunnel_command, tunnel_args].join(" ")
    end

    def tunnel_command
      Pathname.new(File.dirname(__FILE__)).join("../../../support/sc-#{os}/bin/sc").to_s
    end

    def tunnel_args
      ["--user", username, "--api-key", access_key, "--tunnel-identifier", identifier, "--readyfile", ready_file_path].shelljoin
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
