require 'json'
require 'sequel'
require_relative 'hash'

module Bandiera
  autoload :VERSION,        'bandiera/version'
  autoload :Db,             'bandiera/db'
  autoload :Group,          'bandiera/group'
  autoload :Feature,        'bandiera/feature'
  autoload :FeatureService, 'bandiera/feature_service'
  autoload :WebAppBase,     'bandiera/web_app_base'
  autoload :APIv1,          'bandiera/api_v1'
  autoload :APIv2,          'bandiera/api_v2'
  autoload :GUI,            'bandiera/gui'

  def self.init(environment)
    Bundler.setup(:default, environment)
  end
end
