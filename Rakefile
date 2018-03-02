#!/usr/bin/env rake

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'bandiera'
require 'bandiera/anonymous_audit_context'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new

  task default: :spec
  task test: :spec
rescue LoadError
  warn 'Could not load RSpec tasks'
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

  task demo_reset: :environment do |_cmd, _args|
    db   = Bandiera::Db.connect
    serv = Bandiera::FeatureService.new(db: db)

    db[:groups].delete

    serv.add_features(Bandiera::AnonymousAuditContext.new, [
                        {
                          group:       'pubserv',
                          name:        'show-article-metrics',
                          description: 'Show metrics on the article pages?',
                          active:      true
                        },
                        {
                          group:       'pubserv',
                          name:        'show-new-search',
                          description: 'Show the new search feature?',
                          active:      true,
                          percentage:  50
                        },
                        {
                          group:       'pubserv',
                          name:        'show-reorganised-homepage',
                          description: 'Show the new homepage layout?',
                          active:      true,
                          user_groups: { list: ['editor'], regex: '' }
                        }
                      ])
  end
end
