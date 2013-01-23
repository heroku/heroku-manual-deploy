require "heroku/command/base"

class Heroku::Command::Deploy < Heroku::Command::Base

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

  def rolling
    process = shift_argument
    validate_arguments!

    message, options = case process
    when NilClass
      action("Deploying processes\n") do
        api.get_ps(app).body.each do |entry|
          ps = entry['process']
          action("Deploying #{ps} process\n") do
            api.post_ps_restart(app, { :ps => ps })
          end
        end
      end
    when /.+\..+/
      ps = args.first
      action("Deploying #{ps} process\n") do
        api.post_ps_restart(app, { :ps => ps })
      end
    else
      type = args.first
      action("Deploying #{type} process\n") do
        api.get_ps(app).body.each do |entry|
          ps = entry['process']
          if ps.split(".").first == type
            action("Deploying #{ps} process\n") do
              api.post_ps_restart(app, { :ps => ps })
            end
          end
        end
      end
    end
  end
end
