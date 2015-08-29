module Blade::SauceLabsPlugin::CLI
  class Sauce < Thor
    desc "browsers", "Show available browsers"
    def browsers
      browsers = Blade::SauceLabsPlugin::Client.available_platforms_by_browser

      puts
      puts "Available browsers on Sauce Labs"
      puts "--------------------------------"
      puts

      browsers.keys.sort.each do |name|
        puts "#{name}:"
        browsers[name].each do |os, details|
          versions = details[:versions].map do |version|
            if version.to_i.to_s == version
              version.to_i
            else
              version
            end
          end
          puts "  #{os}: #{versions.join(', ')}"
        end

        puts
      end
    end
  end
end

Blade::CLI.register Blade::SauceLabsPlugin::CLI::Sauce, "sauce", "sauce COMMAND", "Sauce Labs commands"
