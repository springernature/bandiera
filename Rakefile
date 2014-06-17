#!/usr/bin/env rake

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require "bandiera"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new

  task :default => :spec
  task :test    => :spec
rescue LoadError
end

namespace :bundler do
  task :setup do
    require "bundler/setup"
  end
end

task :environment, [:env] => "bundler:setup" do |cmd, args|
  ENV["RACK_ENV"] ||= ENV["RAILS_ENV"] || args[:env] || "development"
end

namespace :db do
  desc "Create DB"
  task :create => :environment  do |cmd, args|
    db = Bandiera::Db.params(ENV["RACK_ENV"])
    run_mysql_command(db, "CREATE DATABASE `#{db[:database]}`")
  end

  desc "Drop database"
  task :nuke => :environment do |cmd, args|
    db = Bandiera::Db.params(ENV["RACK_ENV"])
    run_mysql_command(db, "DROP DATABASE `#{db[:database]}`")
  end

  desc "Run database migrations"
  task :migrate => :environment do |cmd, args|
    Sequel.extension :migration
    Sequel::Migrator.apply(Bandiera::Db.connection, "db/migrations")
  end

  desc "Rollback the database"
  task :rollback => :environment do |cmd, args|
    Sequel.extension :migration
    version = (row = Bandiera::Db.connection[:schema_info].first) ? row[:version] : nil
    Sequel::Migrator.apply(Bandiera::Db.connection, "db/migrations", version - 1)
  end

  desc "Drop all tables in database"
  task :drop => :environment do |cmd, args|
    Bandiera::Db.connection.tables.each do |table|
      Bandiera::Db.connection.run("DROP TABLE #{table}")
    end
  end

  desc "Clean Slate"
  task :reset  => [:nuke, :create, :drop, :migrate]
end

private

def run_mysql_command(db, cmd)
  command = "echo '#{cmd}' | mysql -h #{db[:host]} -P #{db[:port]} -u #{db[:user]} --password=#{db[:password]} 2>/dev/null"
  system(command)
end

