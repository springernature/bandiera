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

if ENV['SENTRY_DSN']
  require 'raven'

  Raven.configure do |config|
    config.dsn                 = ENV['SENTRY_DSN']
    config.current_environment = ENV.fetch('RACK_ENV', 'development')
    config.environments        = ['production']
    config.logger              = Bandiera.logger
  end

  use Raven::Rack
end

if ENV['RACK_CORS_ORIGINS']
  require 'rack/cors'

  use Rack::Cors do
    allow do
      origins ENV['RACK_CORS_ORIGINS']
      resource '/api/v2/*', headers: :any, methods: [:get, :options]
    end
  end
end

require 'prometheus/client/rack/collector'
require 'prometheus/client/rack/exporter'
use Prometheus::Client::Rack::Collector
use Prometheus::Client::Rack::Exporter

require 'macmillan/utils/statsd_middleware'
use Macmillan::Utils::StatsdMiddleware, client: Bandiera.statsd

require 'rack/not_so_common_logger'
use Rack::NotSoCommonLogger, Bandiera.logger
use Airbrake::Rack::Middleware if ENV['AIRBRAKE_API_KEY'] && ENV['AIRBRAKE_PROJECT_ID']

run Rack::URLMap.new(
  '/'       => Bandiera::GUI,
  '/api/v1' => Bandiera::APIv1,
  '/api/v2' => Bandiera::APIv2
)
