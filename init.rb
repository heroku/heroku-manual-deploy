$:.unshift(File.expand_path(File.join(Dir.getwd, "lib")))

require "heroku/deploy"
require "heroku/ps"
