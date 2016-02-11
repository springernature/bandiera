$LOAD_PATH.unshift File.join(__FILE__, '../lib')

require 'bandiera'
Bandiera.init(ENV['RACK_ENV'] || 'development')

if ENV['AIRBRAKE_API_KEY'] && ENV['AIRBRAKE_PROJECT_ID']
  require 'socket'
  require 'airbrake'

  Airbrake.configure do |config|
    config.project_key = ENV['AIRBRAKE_API_KEY']
    config.project_id  = ENV['AIRBRAKE_PROJECT_ID']
  end

  Airbrake.add_filter do |notice|
    if notice[:errors].any? { |error| error[:type] == 'Sinatra::NotFound' }
      notice.ignore!
    end
  end
end

require 'macmillan/utils/statsd_middleware'

use Macmillan::Utils::StatsdMiddleware, client: Bandiera.statsd
use Rack::CommonLogger, Bandiera.logger
use Airbrake::Rack::Middleware if ENV['AIRBRAKE_API_KEY'] && ENV['AIRBRAKE_PROJECT_ID']

run Rack::URLMap.new(
  '/'       => Bandiera::GUI,
  '/api/v1' => Bandiera::APIv1,
  '/api/v2' => Bandiera::APIv2
)
