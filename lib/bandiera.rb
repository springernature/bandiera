require "sinatra/base"
require "redis"

module Bandiera
end

require_relative "bandiera/feature"
require_relative "bandiera/repository"
require_relative "bandiera/server"

