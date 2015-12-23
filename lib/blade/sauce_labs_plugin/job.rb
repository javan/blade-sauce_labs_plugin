class Blade::SauceLabsPlugin::Job < EventMachine::Completion
  delegate :client, to: Blade::SauceLabsPlugin

  attr_reader :config, :retries, :web_driver, :session_id

  def initialize(config, retries = 0)
    super()
    @config = config.symbolize_keys
    @retries = retries
    @web_driver = Blade::SauceLabsPlugin::WebDriver.new(config)
  end

  def start
    change_state :pending
    web_driver.callback { start_tests }
    web_driver.errback { fail }
    web_driver.start
  end

  def start_tests
    web_driver.navigate_to(Blade.url) do |success|
      if success
        @id = web_driver.session_id
        @session_id = web_driver.get_cookie(:blade_session)

        if @id.present? && @session_id.present?
          succeed
        else
          fail
        end
      else
        fail
      end
    end
  end

  def stop
    return unless completed?

    web_driver.stop do |success|
      if success
        change_state :stopped
      else
        if client.stop_job(id).success?
          change_state :stopped
        end
      end
    end
  end

  def update(params)
    client.update_job(id, params)
  end

  def stop_and_delete
    job_id = id
    stop

    tries = 0
    timer = EM.add_periodic_timer(8) do
      if client.delete_job(job_id).success?
        timer.cancel
        yield true
      else
        tries += 1
        if tries == 10
          timer.cancel
          yield false
        end
      end
    end
  end

  def id
    if @id.present?
      @id
    else
      @found_id ||= find_id
    end
  end

  private
    def find_id
      match = {
        browser_short_version: config[:version],
        browser: config[:browserName],
        os: config[:platform],
        status: "in progress"
      }

      client.get_jobs(full: true).each do |job|
        job.symbolize_keys!
        if match.all? { |key, value| job[key] == value }
          return job[:id]
        end
      end

      nil
    end
end
