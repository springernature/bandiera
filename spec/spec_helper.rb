ENV['RACK_ENV'] = 'test'
Bundler.setup(:default, ENV['RACK_ENV'])

require 'macmillan/utils/rspec/rspec_defaults'
require 'macmillan/utils/rspec/webmock_helper'
require 'macmillan/utils/test_helpers/codeclimate_helper'
require 'macmillan/utils/test_helpers/simplecov_helper'
require 'macmillan/utils/statsd_stub'

require 'timecop'
require 'pry'

require_relative '../lib/bandiera'
load File.expand_path('../../Rakefile', __FILE__)

# load shared_examples
shared_example_files = File.expand_path('shared_examples/**/*.rb', __dir__)
Dir[shared_example_files].each(&method(:require))

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

  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end
