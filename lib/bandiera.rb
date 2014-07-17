require 'json'
require 'sequel'
require 'macmillan/utils/logger'
require_relative 'hash'

module Bandiera
  autoload :VERSION,        'bandiera/version'
  autoload :Db,             'bandiera/db'
  autoload :Group,          'bandiera/group'
  autoload :Feature,        'bandiera/feature'
  autoload :FeatureUser,    'bandiera/feature_user'
  autoload :FeatureService, 'bandiera/feature_service'
  autoload :WebAppBase,     'bandiera/web_app_base'
  autoload :APIv1,          'bandiera/api_v1'
  autoload :APIv2,          'bandiera/api_v2'
  autoload :GUI,            'bandiera/gui'

  class << self
    def init(environment)
      Bundler.setup(:default, environment)
      Db.connect
    end

    def logger
      @logger ||= Macmillan::Utils::Logger::Factory.build_logger(:syslog, tag: 'bandiera')
    end
    attr_writer :logger
  end
end
