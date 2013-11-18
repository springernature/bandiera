class Server < Sinatra::Base
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

  before do
    Ohm.connect
  end

  get "/api/features/:group/:name" do |group, name|
    group   = Group.find(name: group).first
    feature = group.features.find(name: name).first

    if feature
      feature.to_api
    else
      error 404
    end
  end

  get "/" do
    @features = Feature.all
    erb :index
  end

  get "/new" do
    erb :new
  end

  post "/create" do
    group = Group.find(name: params[:feature][:group]).first || Group.create(name: params[:feature][:group])
    data  = params[:feature].merge({ group: group })

    Feature.create(params[:feature].merge({"group" => group}))
    redirect "/"
  end
end
