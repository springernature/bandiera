$LOAD_PATH.unshift File.join(__FILE__, '../lib')

require 'bandiera'
require 'macmillan/utils/logger/factory'
require 'macmillan/utils/logger/formatter'

logger = Macmillan::Utils::Logger::Factory.build_logger(:syslog, tag: 'bandiera')
logger.formatter = Macmillan::Utils::Logger::Formatter.new

class BandieraLoggerMiddleware
  def initialize(app, logger)
    @app, @logger = app, logger
  end

  def call(env)
    env['rack.logger'] = @logger
    @app.call(env)
  end
end

use Rack::CommonLogger, logger
use BandieraLoggerMiddleware, logger

run Rack::URLMap.new(
  '/'       => Bandiera::GUI,
  '/api/v1' => Bandiera::APIv1,
  '/api/v2' => Bandiera::APIv2
)

