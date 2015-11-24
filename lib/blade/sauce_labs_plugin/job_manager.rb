module Blade::SauceLabsPlugin::JobManager
  extend self

  Job = Blade::SauceLabsPlugin::Job

  delegate :config, :client, to: Blade::SauceLabsPlugin

  cattr_accessor(:job_queue) { EM::Queue.new }
  cattr_accessor(:jobs) { [] }

  def start
    enqueue_jobs
    process_queue
    handle_completed_jobs
  end

  def stop
    jobs.each(&:stop)
  end

  private
    def enqueue_jobs
      client.platforms.each do |platform|
        job_queue << Job.new(platform.merge(test_params))
      end
    end

    def process_queue
      return if job_queue.empty?
      vm_count = client.get_available_vm_count

      if vm_count.zero?
        wait_for_available_vm
      else
        vm_count.times do
          job_queue.pop do |job|
            job.callback do
              jobs << job
            end

            job.errback do
              if job.retries == 3
                exit 1
              else
                job.stop_and_delete do
                  job_queue << Job.new(job.config, job.retries + 1)
                  EM.next_tick { process_queue }
                end
              end
            end

            job.start
          end
        end
      end
    end

    def wait_for_available_vm
      @vm_timer ||= EM.add_periodic_timer 3 do
        unless client.get_available_vm_count.zero?
          @vm_timer.cancel
          @vm_timer = nil
          process_queue
        end
      end
    end

    def handle_completed_jobs
      Blade.subscribe("/results") do |details|
        if details["completed"]
          if job = jobs.detect { |job| job.session_id == details["session_id"] }
            job.update(passed: (details["state"] != "failed"))
            job.stop
            EM.add_timer(1) { process_queue }
          end
        end
      end
    end

    def test_params
      camelize_keys(combined_test_config)
    end

    def combined_test_config
      default_test_config.merge(env_test_config).merge(test_config).select { |k, v| v.present? }
    end

    def test_config
      config.test_config || {}
    end

    def default_test_config
      {
        tunnel_identifier: Blade::SauceLabsPlugin::Tunnel.identifier,
        max_duration: 300,
        name: "Blade Runner CI",
        build: default_build
      }
    end

    def env_test_config
      {}.tap do |config|
        if build = (get_env_value(:build) || get_env_value(:job_number))
          config[:build] = build
        end

        tags = []

        [:commit, :repo_slug, :pull_request].each do |key|
          if tag = tag_from_env(key)
            tags << tag
          end
        end

        config[:tags] = tags if tags.any?
      end
    end

    def tag_from_env(key)
      if value = get_env_value(key)
        [key, value].join(":")
      end
    end

    def get_env_value(key)
      key = key.to_s.upcase
      ENV[key] || ENV["TRAVIS_#{key}"]
    end

    def default_build
      [rev, Time.now.utc.to_i].select(&:present?).join("-")
    end

    def rev
      @rev ||= `git rev-parse HEAD 2>/dev/null`.chomp
    end

    def camelize_keys(hash)
      {}.tap do |result|
        hash.each do |key, value|
          result[key.to_s.camelize(:lower)] = value
        end
      end
    end
end
