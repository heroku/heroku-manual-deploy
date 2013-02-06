require "heroku/command/base"

class Heroku::Command::Deploy < Heroku::Command::Base

  # deploy [PROCESS]
  #
  # deploy processes for an app
  #
  # if PROCESS is not specified, deploy all processes on the app
  #
  #Examples:
  #
  # $ heroku deploy web.1
  # Deploying web.1 process... done
  #
  # $ heroku deploy web
  # Deploying web processes... done
  #
  # $ heroku deploy
  # Deploying processes... done
  #
  def index
    process = shift_argument
    validate_arguments!

    message, options = case process
    when NilClass
      ["Deploying processes", {}]
    when /.+\..+/
      ps = args.first
      ["Deploying #{ps} process", { :ps => ps }]
    else
      type = args.first
      ["Deploying #{type} processes", { :type => type }]
    end

    action(message) do
      api.post_ps_restart(app, options)
    end
  end

  # deploy:rolling
  #
  # deploy processes for an app with a rolling restart
  #
  #Example:
  #
  # $ heroku deploy:rolling
  # Deploying web.1 process... done
  # Deploying web.2 process... done
  # Deploying web.3 process... done
  #
  def rolling
    validate_arguments!
    processes = api.get_ps(app).body.
      map { |p| p.merge("process_type" => p["process"].split(".")[0], "process_num" => p["process"].split(".")[1].to_i) }.
      sort_by { |p| [p["process_type"], p["process_num"]] }
    web_processes = processes.select { |p| p["process_type"] == "web" }
    other_processes = processes - web_processes
    if web_processes.size <= 1
      error("Rolling deploys require at least 2 web processes.")
    end
    total_interval = 60.0
    start = Time.now
    process_interval = total_interval / web_processes.size
    web_processes.each_with_index do |web_process, index|
      ps = web_process["process"]
      action("Deploying #{ps} process") do
        api.post_ps_restart(app, {:ps => ps})
        wait(start + (index+1)*process_interval)
      end
    end
    other_processes.each_with_index do |other_process, index|
      ps = other_process["process"]
      action("Deploying #{ps} process") do
        api.post_ps_restart(app, {:ps => ps})
      end
    end
  end

  private

  def wait(til)
    delta = til - Time.now
    if delta > 0
      sleep(delta)
    end
  end
end
