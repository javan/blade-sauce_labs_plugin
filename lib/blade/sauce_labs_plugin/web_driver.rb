require "selenium/webdriver"

class Blade::SauceLabsPlugin::WebDriver < EventMachine::Completion
  class << self
    delegate :username, :access_key, to: Blade::SauceLabsPlugin
  end

  cattr_accessor(:url ) { "https://#{username}:#{access_key}@ondemand.saucelabs.com:443/wd/hub" }

  attr_reader :capabilities
  attr_reader :driver

  def initialize(capabilities)
    super()
    @capabilities = capabilities
  end

  def start
    EM.defer do
      if @driver = get_driver
        succeed
      else
        fail
      end
    end
  end

  def stop
    EM.defer do
      yield(quit_driver)
    end
  end

  def active?
    completed?
  end

  def navigate_to(url)
    EM.defer do
      begin
        driver.navigate.to(url)

        start = Time.now

        EM.tick_loop do
          if driver.current_url == url
            yield true
            :stop
          elsif Time.now - start > 2
            yield false
            :stop
          end
        end
      rescue
        yield false
      end
    end
  end

  def session_id
    if active?
      driver.session_id
    end
  end

  def get_cookie(name)
    if active? && cookie = driver.manage.cookie_named(name.to_s)
      cookie[:value]
    end
  end

  private
    def get_driver
      driver = Selenium::WebDriver.for(:remote, url: url, http_client: http_client, desired_capabilities: capabilities)
      driver.manage.timeouts.implicit_wait = 10
      driver
    rescue
      nil
    end

    def quit_driver
      return unless active?
      driver.quit
      true
    rescue
      false
    end

    def http_client
      @http_client ||= begin
        client = Selenium::WebDriver::Remote::Http::Default.new
        if client.respond_to?(:open_timeout)
          client.open_timeout = 60
          client.read_timeout = 260
        else
          client.timeout = 260
        end
        client
      end
    end
end
