$LOAD_PATH.unshift File.join(__FILE__, '../lib')

require 'bundler'
require 'bandiera'

Bandiera.init(ENV['RACK_ENV'] || 'development')
logger = Bandiera.logger

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
