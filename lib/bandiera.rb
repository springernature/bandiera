require 'dotenv'
require 'json'
require 'logger'
require 'sequel'
require 'syslog-logger'
require_relative 'hash'

GC::Profiler.enable

module Bandiera
  autoload :VERSION,                'bandiera/version'
  autoload :Db,                     'bandiera/db'
  autoload :WebAuditContext,        'bandiera/web_audit_context'
  autoload :BlackholeAuditLog,      'bandiera/blackhole_audit_log'
  autoload :LoggingAuditLog,        'bandiera/logging_audit_log'
  autoload :AuditRecord,            'bandiera/audit_record'
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
      Dotenv.load
      Db.connect
    end

    def logger
      return @logger if @logger

      @logger = if ENV['LOG_TO_STDOUT']
                  Logger.new($stdout)
                else
                  Logger::Syslog.new('bandiera', Syslog::LOG_LOCAL0)
                end

      if ENV['STACKDRIVER_JSON_LOGGER']
        require 'logger/stackdriver_json_formatter'
        @logger.formatter = Logger::StackdriverJsonFormatter.new
      end

      @logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'INFO').upcase)

      @logger
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
