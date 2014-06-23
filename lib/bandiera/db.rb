require 'sequel'
require 'yaml'

Sequel.extension :migration
Sequel::Model.plugin :update_or_create

module Bandiera
  class Db
    def self.configuration
      @configuration ||= YAML.load(File.open(File.join('config', 'database.yml')))
    end

    def self.connection
      @connection ||= Sequel.connect(connection_string)
    end

    def self.disconnect!
      @connection.disconnect if @connection
      @connection = nil
    end

    def self.params(env)
      {
        host:         configuration[env]['host'],
        port:         configuration[env]['port'],
        user:         configuration[env]['username'],
        password:     configuration[env]['password'],
        encoding:     configuration[env]['encoding'],
        database:     configuration[env]['database']
      }
    end

    def self.connection_string
      return ENV['DATABASE_URL'] if ENV['DATABASE_URL']

      conn = params(ENV['RACK_ENV'])

      if RUBY_PLATFORM == 'java'
        str = "jdbc:mysql://#{conn[:host]}:#{conn[:port]}/#{conn[:database]}?user=#{conn[:user]}"
        str << "&password=#{conn[:password]}" if conn[:password]
        str << '&useUnicode=true&characterEncoding=utf8'
        str
      else
        conn.merge(adapter: 'mysql2', encoding: 'utf8', max_connections: 10, reconnect: true)
      end
    end
  end
end
