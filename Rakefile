#!/usr/bin/env rake

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'bandiera'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new

  task default: :spec
  task test: :spec
rescue LoadError
end

namespace :bundler do
  task :setup do
    require 'bundler/setup'
  end
end

task :environment, [:env] => 'bundler:setup' do |_cmd, args|
  ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || args[:env] || 'development'
end

namespace :db do
  desc 'Run DB migrations'
  task migrate: :environment do |_cmd, _args|
    Bandiera::Db.migrate
  end

  desc 'Rollback the DB'
  task rollback: :environment do |_cmd, _args|
    Bandiera::Db.rollback
  end
end
