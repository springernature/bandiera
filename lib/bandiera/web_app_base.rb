require 'sinatra/base'
require 'macmillan/utils/statsd_controller_helper'

module Bandiera
  class WebAppBase < Sinatra::Base
    class InvalidParams < StandardError; end

    include Macmillan::Utils::StatsdControllerHelper

    configure do
      enable :logging
      enable :raise_errors if ENV['AIRBRAKE_API_KEY'] && ENV['AIRBRAKE_PROJECT_ID']

      set :feature_service, CachingFeatureService.new(FeatureService.new)
    end

    helpers do
      def feature_service
        settings.feature_service
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
        percentage:  params['percentage'],
        start_time:  params['start_time'],
        end_time:    params['end_time']
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
      valid_name = param_present?(feature[:name]) && !param_has_whitespace?(feature[:name])

      valid_times = true
      valid_times = false if param_present?(feature[:start_time]) && !param_present?(feature[:end_time])
      valid_times = false if param_present?(feature[:end_time]) && !param_present?(feature[:start_time])
      valid_times = false if param_present?(feature[:start_time]) && param_present?(feature[:end_time]) && !times_in_order?(feature[:start_time], feature[:end_time])

      valid_name && param_present?(feature[:group]) && valid_times
    end

    def param_present?(param)
      param && !param.empty?
    end

    def param_has_whitespace?(param)
      param.match(/\s/)
    end

    def times_in_order?(start_time, end_time)
      start_time = Time.parse(start_time)
      end_time = Time.parse(end_time)

      (start_time < end_time)
    end
  end
end
