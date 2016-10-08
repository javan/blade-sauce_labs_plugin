require "childprocess"
require "securerandom"

module Blade::SauceLabsPlugin::Tunnel
  extend self

  extend Forwardable
  def_delegators Blade::SauceLabsPlugin, :username, :access_key, :tunnel_timeout, :config, :debug, :debug?

  attr_reader :identifier, :process

  def start
    @identifier = SecureRandom.hex(10)
    @process = create_child_process

    started_at = Time.now
    timer = EM::PeriodicTimer.new(1) do
      if ready_file_exists?
        timer.cancel
        yield
      elsif !debug?
        elapsed = Time.now - started_at
        if elapsed > tunnel_timeout
          timer.cancel
          STDERR.puts "Failed to establish tunnel connection after #{elapsed}s:"
          STDERR.puts tunnel_io.tap(&:rewind).read
          exit(1)
        end
      end
    end
  end

  def stop
    begin
      tunnel_io.unlink
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
        if debug?
          process.io.inherit!
        else
          process.io.stdout = process.io.stderr = tunnel_io
          process.duplex = true
        end
        process.leader = true
        process.environment.merge! tunnel_env
        process.start
        debug process.inspect
      end
    end

    def tunnel_command
      Pathname.new(File.dirname(__FILE__)).join("../../../support/sc-#{os}/bin/sc").to_s
    end

    def tunnel_args
      ["--tunnel-identifier", identifier, "--readyfile", ready_file_path] + Array(config.tunnel_args)
    end

    def tunnel_env
      { "SAUCE_USERNAME" => username, "SAUCE_ACCESS_KEY" => access_key }
    end

    def tunnel_io
      @tunnel_io ||= Tempfile.new("blade_sauce_tunel_#{identifier}").tap { |io| io.sync = true }
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
