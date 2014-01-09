require "sequel"
require "yaml"

Sequel.extension :migration

module Bandiera
  class Db
    CONFIG = YAML::load(File.open(File.join("config", "database.yml")))

    def self.connection
      @connection ||= Sequel.connect(connection_string)
    end

    def self.params(env)
      {
        host:         CONFIG[env]["host"],
        port:         CONFIG[env]["port"],
        user:         CONFIG[env]["username"],
        password:     CONFIG[env]["password"],
        encoding:     CONFIG[env]["encoding"],
        database:     CONFIG[env]["database"]
      }
    end

    def self.connection_string
      conn = params(ENV["RACK_ENV"])

      if RUBY_PLATFORM == "java"
        str = "jdbc:mysql://#{conn[:host]}:#{conn[:port]}/#{conn[:database]}?user=#{conn[:user]}"
        str << "&password=#{conn[:password]}" if conn[:password]
        str << "&useUnicode=true&characterEncoding=utf8"
        str
      else
        conn.merge(adapter: "mysql2", encoding: "utf8")
      end
    end
  end
end
