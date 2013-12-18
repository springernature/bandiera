require "sinatra/base"
require "sequel"
require "yaml"

Sequel.extension :migration

module Bandiera
  class Db
    CONFIG = YAML::load(File.open(File.join("config", "database.yml")))

    def self.params(env)
      {
        adapter:      CONFIG[env]["adapter"],
        host:         CONFIG[env]["host"],
        port:         CONFIG[env]["port"],
        user:         CONFIG[env]["username"],
        password:     CONFIG[env]["password"],
        encoding:     CONFIG[env]["encoding"],
        database:     CONFIG[env]["database"]
      }
    end

    def self.connection
      @connection ||= Sequel.connect(params(ENV["RACK_ENV"]))
    end
  end
end
