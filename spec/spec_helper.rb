require "bundler"
Bundler.setup(:default, :test)

ENV["RACK_ENV"] = "test"

require "rspec"
require "rake"
require "pry"
require "webmock/rspec"
require "simplecov"
require "simplecov-rcov"

WebMock.disable_net_connect!

class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end

SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

SimpleCov.start do
  load_adapter    "test_frameworks"
  merge_timeout   3600
  add_group       "Lib", "lib"
end

load File.expand_path("../../Rakefile", __FILE__)

require_relative "../lib/bandiera"

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

