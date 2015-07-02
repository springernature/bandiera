require 'sinatra/base'
require 'macmillan/utils/statsd_controller_helper'

if ENV['AIRBRAKE_API_KEY']
  require 'socket'
  require 'airbrake'

  Airbrake.configure do |config|
    config.api_key = ENV['AIRBRAKE_API_KEY']
    config.ignore << 'Sinatra::NotFound'

    if ENV['MACMILLAN_ENV']
      config.development_environments = []
      config.environment_name         = case Socket.gethostname
                                        when /test/    then 'test'
                                        when /staging/ then 'staging'
                                        else
                                          'live'
                                        end
    end
  end
end

module Bandiera
  class WebAppBase < Sinatra::Base
    class InvalidParams < StandardError; end

    include Macmillan::Utils::StatsdControllerHelper

    use Airbrake::Sinatra if ENV['AIRBRAKE_API_KEY']

    configure do
      enable :logging
      enable :raise_errors if ENV['AIRBRAKE_API_KEY']
    end

    helpers do
      def feature_service
        @feature_service ||= FeatureService.new
      end
    end

    before do
      path   = request.path.sub(%r{^/}, '').gsub('/', '.')
      path   = 'homepage' if path.empty?
      method = request.request_method.downcase
      add_statsd_timer_and_increment "#{path}.#{method}"
    end

    private

    def process_v1_feature_params(params)
      {
        group:       params['group'],
        name:        params['name'],
        description: params['description'],
        active:      params['enabled'] == 'true',
        percentage:  params['percentage']
      }
    end

    def process_v2_feature_params(params)
      user_group_params = params.fetch('user_groups', {}).symbolize_keys
      user_groups       = {
        list:  process_user_group_list_param(user_group_params.fetch(:list, '')),
        regex: user_group_params.fetch(:regex, '')
      }

      {
        group:       params['group'],
        name:        params['name'],
        description: params['description'],
        active:      params['active'] == 'true',
        user_groups: user_groups,
        percentage:  params['percentage']
      }
    end

    def process_user_group_list_param(val)
      list = case val
             when String then val.split("\n")
             when Array  then val
             else
               fail InvalidParams, 'params[user_groups][list] must be a string or array.'
             end

      list.map(&:strip)
    end

    def valid_params?(feature)
      param_present?(feature[:name]) && !feature[:name].include?(' ') && param_present?(feature[:group])
    end

    def param_present?(param)
      param && !param.empty?
    end
  end
end
