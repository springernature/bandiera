ENV['RACK_ENV'] = 'test'
Bundler.setup(:default, ENV['RACK_ENV'])

require 'macmillan/utils/rspec/rspec_defaults'
require 'macmillan/utils/rspec/webmock_helper'
require 'macmillan/utils/test_helpers/codeclimate_helper'
require 'macmillan/utils/test_helpers/simplecov_helper'

require_relative '../lib/bandiera'
load File.expand_path('../../Rakefile', __FILE__)

db = Bandiera::Db.connection

RSpec.configure do |config|
  config.before(:suite) do
    Rake::Task['db:reset'].invoke(ENV['RACK_ENV'])
  end

  config.after(:each) do
    db[:groups].delete
  end
end
