require "sinatra/base"
require "sequel"
require "yaml"

Sequel.extension :migration

DB_CONFIG = YAML::load(File.open(File.join("config", "database.yml")))

class BandieraConfig < Sinatra::Base
  def self.db_params(env)
    {
      adapter:      DB_CONFIG[env]["adapter"],
      host:         DB_CONFIG[env]["host"],
      port:         DB_CONFIG[env]["port"],
      user:         DB_CONFIG[env]["username"],
      password:     DB_CONFIG[env]["password"],
      encoding:     DB_CONFIG[env]["encoding"],
      database:     DB_CONFIG[env]["database"]
    }
  end

  configure :development do
    set :environment, :development
    Bundler.setup(:default, :development, :assets)
    enable :sessions, :logging, :static, :inline_templates, :method_override, :dump_errors, :run
    DB = Sequel.connect(BandieraConfig.db_params(settings.environment.to_s))
  end

  configure :test do
    set :environment, :test
    Bundler.setup(:default, :test)
    enable :sessions, :static, :inline_templates, :method_override, :raise_errors
    disable :run, :dump_errors, :logging
    DB = Sequel.connect(BandieraConfig.db_params(settings.environment.to_s))
  end

  configure :production do
    set :environment, :production
    Bundler.setup(:default, :production)
    enable :sessions, :logging, :static, :inline_templates, :method_override, :dump_errors, :run
    DB = Sequel.connect(BandieraConfig.db_params(settings.environment.to_s))
  end
end
