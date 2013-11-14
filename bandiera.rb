require "sinatra/base"
require "json"
require "logger"

class Bandiera < Sinatra::Base
  configure :production, :development do
    set :port, ENV["PORT"]
    enable :logging
  end

  helpers do
    def logger
      $logger
    end

    def redis
      @redis ||= begin do
        Redis.new
      end
    end
  end


end


