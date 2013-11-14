require "sinatra/base"
require "json"
require "logger"

class Bandiera < Sinatra::Base
  configure do
    set :port, ENV["PORT"]
    enable :raise_errors
    disable :show_exceptions
    enable :dump_errors
    enable :logging
  end

  helpers do
    def logger
      $logger
    end
  end

  get "/api/features/:group/:name" do |group, name|
    feature = Repository.get(group, name)

    if feature
      feature.to_api
    else
      error 404
    end
  end
end

require_relative "lib/bandiera/feature"
require_relative "lib/bandiera/repository"

