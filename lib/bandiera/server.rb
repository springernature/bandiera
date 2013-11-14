require "sinatra/base"
require "json"

require_relative "feature"
require_relative "repository"

class Bandiera::Server < Sinatra::Base
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
    feature = Bandiera::Repository.get(group, name)

    if feature
      feature.to_api
    else
      error 404
    end
  end
end
