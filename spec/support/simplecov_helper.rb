require 'simplecov'
require 'simplecov-rcov'

formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter
]

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  formatters << CodeClimate::TestReporter::Formatter
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[*formatters]

SimpleCov.start do
  load_profile 'test_frameworks'
  merge_timeout 3600
  add_group 'Lib', 'lib'
end
