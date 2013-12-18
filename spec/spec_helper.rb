require "bundler"
Bundler.setup(:default, :test)

ENV["RACK_ENV"] = "test"

require "rspec"
require "pry"

require_relative "../bandiera"

require "database_cleaner"
DatabaseCleaner[:sequel, { connection: BandieraConfig::DB }]
DatabaseCleaner.strategy = :transaction

require "rake"
load File.expand_path("../../Rakefile", __FILE__)

RSpec.configure do |config|
  config.order = "random"

  config.before(:suite) do
    Rake::Task["db:reset"].invoke(ENV["RACK_ENV"])
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

