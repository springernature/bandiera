require "bundler"
Bundler.setup(:default, :test)

ENV["RACK_ENV"] = "test"

require "rspec"
require "pry"

require "webmock/rspec"
WebMock.disable_net_connect!

require_relative "../lib/bandiera"

require "rake"
load File.expand_path("../../Rakefile", __FILE__)

db = Bandiera::Db.connection

RSpec.configure do |config|
  config.order = "random"

  config.before(:suite) do
    Rake::Task["db:reset"].invoke(ENV["RACK_ENV"])
  end

  config.after(:each) do
    db[:groups].delete
  end
end

