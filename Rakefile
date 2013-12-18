require "pry"
require_relative "config/bandiera_config"

namespace :bundler do
  task :setup do
    require "bundler/setup"
  end
end

task :environment, [:env] => "bundler:setup" do |cmd, args|
  ENV["RACK_ENV"] = args[:env] || "development"
end

namespace :db do
  desc "Create DB"
  task :create, :env do |cmd, args|
    env = args[:env] || "development"
    db  = BandieraConfig.db_params(env)
    Rake::Task["environment"].invoke(env)
    run_mysql_command(db, "CREATE DATABASE `#{db[:database]}`")
  end

  desc "Drop database"
  task :nuke, :env do |cmd, args|
    env = args[:env] || "development"
    db  = BandieraConfig.db_params(env)
    Rake::Task["environment"].invoke(env)
    run_mysql_command(db, "DROP DATABASE `#{db[:database]}`")
  end

  desc "Run database migrations"
  task :migrate, :env do |cmd, args|
    env = args[:env] || "development"
    Rake::Task["environment"].invoke(env)

    Sequel.extension :migration
    Sequel::Migrator.apply(BandieraConfig::DB, "db/migrations")
  end

  desc "Rollback the database"
  task :rollback, :env do |cmd, args|
    env = args[:env] || "development"
    Rake::Task["environment"].invoke(env)

    Sequel.extension :migration
    version = (row = BandieraConfig::DB[:schema_info].first) ? row[:version] : nil
    Sequel::Migrator.apply(BandieraConfig::DB, "db/migrations", version - 1)
  end

  desc "Drop all tables in database"
  task :drop, :env do |cmd, args|
    env = args[:env] || "development"
    Rake::Task["environment"].invoke(env)
    BandieraConfig::DB.tables.each do |table|
      BandieraConfig::DB.run("DROP TABLE #{table}")
    end
  end

  desc "Clean Slate"
  task :reset, [:env] => [:nuke, :create, :drop, :migrate]
end

private

def run_mysql_command(db, cmd)
  command = "echo '#{cmd}' | mysql -h #{db[:host]} -P #{db[:port]} -u #{db[:user]} --password=#{db[:password]} 2>/dev/null"
  system(command)
end

