ENV['RACK_ENV'] = 'test'
Bundler.setup(:default, ENV['RACK_ENV'])

require 'macmillan/utils/rspec/rspec_defaults'
require 'macmillan/utils/rspec/webmock_helper'
require 'macmillan/utils/test_helpers/codeclimate_helper'
require 'macmillan/utils/test_helpers/simplecov_helper'
require 'macmillan/utils/statsd_stub'

require 'pry'

require_relative '../lib/bandiera'
load File.expand_path('../../Rakefile', __FILE__)

# Suppress logging
Bandiera.logger = Macmillan::Utils::Logger::Factory.build_logger(:null)
Bandiera.statsd = Macmillan::Utils::StatsdStub.new

# use an in-memory sqlite database for testing
ENV['DATABASE_URL'] = 'sqlite:/'
ENV['DATABASE_URL'] = 'jdbc:sqlite:' if RUBY_PLATFORM == 'java'

DB = Bandiera::Db.connect
Bandiera::Db.migrate

RSpec.configure do |config|
  config.after(:each) do
    DB[:features].delete
    DB[:groups].delete
  end
end
