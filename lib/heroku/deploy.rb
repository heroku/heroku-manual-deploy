require "heroku/command/base"

class Heroku::Command::Deploy < Heroku::Command::Base

  # deploy [PROCESS]
  #
  # deploy an app
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

  # deploy:rolling [PROCESS]
  #
  # rolling deploy of an app
  #
  # if PROCESS is not specified, deploy all processes on the app
  # -i, --interval SECONDS  # time between deploys
  #
  #Examples:
  #
  # $ heroku deploy:rolling web.1
  # Deploying web.1 process... done
  #
  # $ heroku deploy:rolling web
  # Deploying web processes...
  # Deploying web.1 process... done
  # done
  #
  # $ heroku deploy:rolling
  # Deploying processes...
  # Deploying web.1 process... done
  # done
  #
  def rolling
    process = shift_argument
    validate_arguments!
    interval = (options[:interval] || "20").to_i

    message, options = case process
    when NilClass
      action("Deploying processes") do
        first = true
        entries = api.get_ps(app).body
        entries.each_with_index do |entry, index|
          ps = entry['process']
          action((first ? "\n" : "") + "Deploying #{ps} process") do
            api.post_ps_restart(app, { :ps => ps })
          end
          first = false
          sleep(interval) if (index+1 != entries.size)
        end
      end
    when /.+\..+/
      ps = args.first
      action("Deploying #{ps} process") do
        api.post_ps_restart(app, { :ps => ps })
      end
    else
      type = args.first
        action("Deploying #{type} process") do
        first = true
        entries = api.get_ps(app).body
        entries.each_with_index do |entry, index|
          ps = entry['process']
          if ps.split(".").first == type
            action((first ? "\n" : "") + "Deploying #{ps} process") do
              api.post_ps_restart(app, { :ps => ps })
            end
            first = false
            sleep(interval) if (index+1 != entries.size)
          end
        end
      end
    end
  end
end
