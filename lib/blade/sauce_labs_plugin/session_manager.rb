module Blade::SauceLabsPlugin::SessionManager
  extend self

  delegate :client, to: Blade::SauceLabsPlugin

  mattr_accessor(:sessions) { Hash.new }

  def start
    Blade.config.expected_sessions = client.platforms.size
    handle_completed_jobs
  end

  def stop
  end

  def update(session_id, data = {})
    session =
      if sessions[session_id]
        sessions[session_id].merge!(data)
      else
        sessions[session_id] = data
      end

    if session.has_key?(:job) && session.has_key?(:passed)
      session[:job].update(passed: session[:passed])
      session[:job].stop
    end
  end

  private
    def handle_completed_jobs
      Blade.subscribe("/results") do |details|
        if details[:completed]
          passed = details[:state] != "failed"
          update(details[:session_id], passed: passed)
        end
      end
    end
end
