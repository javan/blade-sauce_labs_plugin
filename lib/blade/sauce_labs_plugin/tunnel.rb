require "childprocess"

module Blade::SauceLabsPlugin::Tunnel
  extend self

  extend Forwardable
  def_delegators Blade::SauceLabsPlugin, :username, :access_key

  def start
    return if @process
    cmd = Pathname.new(File.dirname(__FILE__)).join("../../../support/sc-#{os}/bin/sc").to_s
    @process = ChildProcess.build(cmd, "--user", username, "--api-key", access_key, "--no-ssl-bump-domains", "*")
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

  def stop
    return unless @process
    @process.stop
  end

  private
    def os
      @os ||=
        case RUBY_PLATFORM.downcase
        when /linux/   then :linux
        when /darwin/  then :osx
        when /windows/ then :windows
        end
    end
end
