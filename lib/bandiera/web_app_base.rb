require 'sinatra/base'
require 'macmillan/utils/statsd_controller_helper'

module Bandiera
  class WebAppBase < Sinatra::Base
    class InvalidParams < StandardError; end

    include Macmillan::Utils::StatsdControllerHelper

    configure do
      enable :logging
      enable :raise_errors if ENV['AIRBRAKE_API_KEY'] && ENV['AIRBRAKE_PROJECT_ID']
    end

    helpers do
      def feature_service
        @feature_service ||= FeatureService.new
      end
    end

    before do
      path   = request.path.sub(%r{^/}, '').tr('/', '.')
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
               raise InvalidParams, 'params[user_groups][list] must be a string or array.'
             end

      list.map(&:strip)
    end

    def valid_feature_params?(feature)
      param_present?(feature[:name]) && !param_has_whitespace?(feature[:name]) && param_present?(feature[:group])
    end

    def param_present?(param)
      param && !param.empty?
    end

    def param_has_whitespace?(param)
      param.match(/\s/)
    end
  end
end
