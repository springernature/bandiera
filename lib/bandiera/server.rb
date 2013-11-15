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

  get "/" do
    erb :index
  end

  get "/new" do
    erb :new
  end

  post "/create" do
    data = {
      name:        params[:feature][:name],
      group:       params[:feature][:group],
      description: params[:feature][:description]
    }
    feature = Feature.new(data)
    Repository.set(feature)
    redirect "/"
  end

end

require_relative "lib/bandiera/feature"
require_relative "lib/bandiera/repository"
