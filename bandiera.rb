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
  end

  get "/api/features/:group/:name" do |group, name|
    begin
      feature = Repository.get(group, name)

      if feature
        feature.to_api
      else
        error 404
      end

    rescue => e
      puts e
      error 500, { error: e }.to_json
    end
  end
end

require_relative "lib/bandiera/feature"
require_relative "lib/bandiera/repository"

