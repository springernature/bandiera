require 'sequel'
require 'yaml'

Sequel.extension :migration
Sequel::Model.plugin :update_or_create

module Bandiera
  class Db
    def self.connect
      @db ||= Sequel.connect(connection_string, loggers: [Bandiera.logger])
    end

    def self.disconnect
      @db.disconnect if @db
      @db = nil
    end

    def self.migrate
      Sequel::Migrator.apply(connect, migrations_dir)
    end

    def self.rollback
      version = (row = connect[:schema_info].first) ? row[:version] : nil
      Sequel::Migrator.apply(connect, migrations_dir, version - 1)
    end

    private

    def self.configuration
      @configuration ||= begin
        database_conf = File.join(File.dirname(__FILE__), '../../config/database.yml')
        fail "Cannot find '#{database_conf}' file" unless File.exist?(database_conf)

        YAML.load(File.read(database_conf))
      end
    end

    def self.params
      {
        host:         configuration['host'],
        port:         configuration['port'],
        user:         configuration['username'],
        password:     configuration['password'],
        encoding:     configuration['encoding'],
        database:     configuration['database'],
        adapter:      configuration['adapter'],
      }
    end

    def self.connection_string
      return ENV['DATABASE_URL'] if ENV['DATABASE_URL']

      conn = params

      if RUBY_PLATFORM == 'java'
        str = "jdbc:#{conn[:adapter]}://#{conn[:host]}:#{conn[:port]}/#{conn[:database]}?user=#{conn[:user]}"
        str << "&password=#{conn[:password]}" if conn[:password]
        str << '&useUnicode=true&characterEncoding=utf8'
        str
      else
        conn.merge(max_connections: 10, reconnect: true)
      end
    end

    def self.migrations_dir
      File.join(File.dirname(__FILE__), '../../db/migrations')
    end
  end
end
