$LOAD_PATH.unshift File.join(__FILE__, '../lib')

require 'bandiera'
Bandiera.init(ENV['RACK_ENV'] || 'development')

require 'macmillan/utils/statsd_middleware'

use Macmillan::Utils::StatsdMiddleware, client: Bandiera.statsd
use Rack::CommonLogger, Bandiera.logger

run Rack::URLMap.new(
  '/'       => Bandiera::GUI,
  '/api/v1' => Bandiera::APIv1,
  '/api/v2' => Bandiera::APIv2
)
