require 'sequel'
require 'yaml'

Sequel.extension :migration
Sequel::Model.plugin :update_or_create

module Bandiera
  class Db
    def self.connect
      fail ArgumentError, 'You must set a DATABASE_URL environment variable' unless ENV['DATABASE_URL']
      @db ||= Sequel.connect(ENV['DATABASE_URL'])
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
  end
end
