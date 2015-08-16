module BladeRunner::SauceLabsPlugin::CLI
  class Sauce < Thor
    desc "browsers", "Show available browsers"
    def browsers
      platforms = BladeRunner::SauceLabsPlugin::Client.available_platforms_by_browser

      puts
      puts "Available browsers on Sauce Labs"
      puts "--------------------------------"
      puts

      platforms.each do |name, details|
        aliases, versions = details.values_at(:aliases, :versions)

        short_names = aliases.any? ? "(#{aliases.join(', ')})" : ""
        puts "#{name} #{short_names}"

        versions.each do |os, versions_for_os|
          puts "  #{os}: #{versions_for_os.join(', ')}"
        end

        puts
      end
    end
  end
end

BladeRunner::CLI.register BladeRunner::SauceLabsPlugin::CLI::Sauce, "sauce", "sauce COMMAND", "Sauce Labs commands"
