require 'sinatra/base'

module Bandiera
  class WebAppBase < Sinatra::Base
    class InvalidParams < StandardError; end

    configure do
      enable :logging
    end

    helpers do
      def feature_service
        @feature_service ||= FeatureService.new
      end

      def logger
        request.logger
      end
    end

    private

    def process_v1_feature_params(params)
      {
        group:        params['group'],
        name:         params['name'],
        description:  params['description'],
        active:       params['enabled'] == 'true'
      }
    end

    def process_v2_feature_params(params)
      user_group_params = params.fetch('user_groups', {}).symbolize_keys
      user_groups       = {
        list:   process_user_group_list_param(user_group_params.fetch(:list, '')),
        regex:  user_group_params.fetch(:regex, '')
      }

      {
        group:        params['group'],
        name:         params['name'],
        description:  params['description'],
        active:       params['active'] == 'true',
        user_groups:  user_groups
      }
    end

    def process_user_group_list_param(val)
      list = case val
             when String then val.split("\n")
             when Array  then val
             else
               fail InvalidParams, "params[user_groups][list] must be a string or array."
             end

      list.map { |elm| elm.strip }
    end

    def valid_params?(feature)
      param_present?(feature[:name]) && param_present?(feature[:group]) && !feature[:name].include?(' ')
    end

    def param_present?(param)
      param && !param.empty?
    end
  end
end
