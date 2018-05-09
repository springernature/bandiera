require 'sequel'
require 'yaml'

Sequel.extension :migration
Sequel::Model.plugin :update_or_create

module Bandiera
  class Db
    def self.connect
      database_url = ENV['DATABASE_URL']
      if database_url.nil?
        if ENV['PG_DB_USER'].nil? || ENV['PG_DB_PASSWORD'].nil? || ENV['PG_DB_HOST'].nil?
          raise ArgumentError, 'You must set a DATABASE_URL environment variable or PG_DB_USER, PG_DB_PASSWORD and PG_DB_HOST' 
        end
        database_url = "postgres://#{ENV['PG_DB_USER']}:#{ENV['PG_DB_PASSWORD']}@#{ENV['PG_DB_HOST']}/bandiera"
      end
      @db ||= Sequel.connect(database_url)
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

    def self.migrations_dir
      File.join(File.dirname(__FILE__), '../../db/migrations')
    end

    def self.ready?
      connect.execute('SELECT 1')
      true
    rescue Sequel::Error
      false
    end
  end
end
