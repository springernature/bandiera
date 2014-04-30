require 'bundler'
Bundler.setup(:default, :test)

require_relative 'support/codeclimate_helper'

ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rake'
require 'pry'

require_relative 'support/webmock_helper'
require_relative 'support/simplecov_helper'

require_relative '../lib/bandiera'

load File.expand_path('../../Rakefile', __FILE__)

db = Bandiera::Db.connection

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    Rake::Task['db:reset'].invoke(ENV['RACK_ENV'])
  end

  config.after(:suite) do
    WebMock.disable!
  end

  config.after(:each) do
    db[:groups].delete
  end
end
