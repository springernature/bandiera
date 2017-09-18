require 'json'
require 'dotenv'
require 'sequel'
require 'macmillan/utils/logger'
require_relative 'hash'
require 'newrelic_rpm'

GC::Profiler.enable

module Bandiera
  autoload :VERSION,                'bandiera/version'
  autoload :Db,                     'bandiera/db'
  autoload :Group,                  'bandiera/group'
  autoload :Feature,                'bandiera/feature'
  autoload :FeatureService,         'bandiera/feature_service'
  autoload :CachingFeatureService,  'bandiera/caching_feature_service'
  autoload :WebAppBase,             'bandiera/web_app_base'
  autoload :APIv1,                  'bandiera/api_v1'
  autoload :APIv2,                  'bandiera/api_v2'
  autoload :GUI,                    'bandiera/gui'

  class << self
    def init(environment)
      Bundler.setup(:default, environment)
      Dotenv.load
      Db.connect
    end

    def logger
      @logger ||= begin
                    if ENV['LOG_TO_STDOUT']
                      Macmillan::Utils::Logger::Factory.build_logger
                    else
                      Macmillan::Utils::Logger::Factory.build_logger(:syslog, tag: 'bandiera')
                    end
                  end
    end
    attr_writer :logger

    def statsd
      @statsd ||= begin
                    if ENV['STATSD_HOST'] && ENV['STATSD_PORT']
                      build_statsd_client
                    else
                      require 'macmillan/utils/statsd_stub'
                      Macmillan::Utils::StatsdStub.new
                    end
                  end
    end
    attr_writer :statsd

    private

    def build_statsd_client
      require 'statsd-ruby'
      require 'macmillan/utils/statsd_decorator'

      statsd = Statsd.new(ENV['STATSD_HOST'], ENV['STATSD_PORT'])
      statsd.namespace = statsd_namespace
      Macmillan::Utils::StatsdDecorator.new(statsd, ENV['RACK_ENV'], logger)
    end

    def statsd_namespace
      hostname = `hostname`.chomp.downcase.sub('.nature.com', '')
      tier     = hostname =~ /test/ ? 'test' : 'live'

      ['bandiera', tier, hostname, RUBY_ENGINE].join('.')
    end
  end
end
