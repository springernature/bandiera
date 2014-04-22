$LOAD_PATH.unshift File.join(__FILE__, '../lib')

require 'bandiera'
require 'syslog-logger'

class Logger::Syslog
  alias_method :write, :info
end

logger = Logger::Syslog.new('bandiera', Syslog::LOG_LOCAL0)

class BandieraLoggerMiddleware
  def initialize(app, logger)
    @app, @logger = app, logger
  end

  def call(env)
    env['bandiera-logger'] = @logger
    @app.call(env)
  end
end

use Rack::CommonLogger, logger
use BandieraLoggerMiddleware, logger

run Rack::URLMap.new(
  '/'    => Bandiera::GUI,
  '/api' => Bandiera::API
)

