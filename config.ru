require "sinatra"
require "newrelic_rpm"

require "syslog-logger"
require "bandiera/syslog_formatter"

class ::Logger::Syslog; alias_method :write, :<<; end

$logger = Logger::Syslog.new("bandiera", Syslog::LOG_LOCAL0)
$logger.formatter = SyslogFormatter.new
$logger.level = Logger::DEBUG

use Rack::CommonLogger, $logger

require File.expand_path "../bandiera.rb", __FILE__

run Bandiera
