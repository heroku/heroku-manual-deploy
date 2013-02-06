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
  # Deploying processes... (=========                     )
  #
  def rolling
    validate_arguments!
    processes = api.get_ps(app).body.map do |p|
      p.merge("process_type" => p["process"].split(".")[0],
              "process_num" => p["process"].split(".")[1].to_i)
    end
    process_counts = processes.inject({}) do |counts, process|
      counts[process["process_type"]] ||= 0
      counts[process["process_type"]] += 1
      counts
    end
    processes.sort_by! do |p|
      (p["process_num"].to_f / process_counts[p["process_type"]].to_f)
    end

    start = Time.now
    deployed = 0
    total = processes.count
    width = total.to_s.length
    interval = 60
    (1..interval).each do |progress|
      ticker = ["-", "\\", "|", "/"][progress % 4]
      $stdout.print("\r")
      if processes.count <= 15
        $stdout.printf("Deploying processes... (%-#{width}s/%-#{width}s) %s", deployed.to_s, total.to_s, ticker)
      else
        $stdout.printf("Deploying processes... (%-#{width}s/%-#{width}s)", deployed.to_s, total.to_s)
      end
      $stdout.flush()
      processes.each_with_index do |process, index|
        if (((index / processes.size.to_f) * (interval -1).to_f).to_i + 1) == progress
          api.post_ps_restart(app, {:ps => process["process"]})
          deployed += 1
        end
      end
      wait_til(start + progress) if (progress != interval)
    end
    $stdout.print("\r")
    $stdout.print("Deploying processes... done#{" " * 6}\n")
    $stdout.flush()
  end

  private

  def wait_til(t)
    delta = t.to_f - Time.now.to_f
    if delta > 0
      sleep(delta)
    end
  end
end
