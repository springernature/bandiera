require 'bundler'
Bundler.setup(:default, :test)

require 'macmillan/utils/rspec/rspec_defaults'
require 'macmillan/utils/rspec/webmock_helper'
require 'macmillan/utils/test_helpers/codeclimate_helper'
require 'macmillan/utils/test_helpers/simplecov_helper'

ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rake'
require 'pry'

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
