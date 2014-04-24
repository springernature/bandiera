require 'sinatra/base'
require 'json'

module Bandiera
  class API < Sinatra::Base
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

    before do
      content_type :json
    end

    get '/v1/groups' do
      groups = feature_service.get_groups.map { |name| { name: name } }
      JSON.generate(groups: groups)
    end

    post '/v1/groups' do
      group_params = params.fetch('group', {})
      group_name   = group_params.fetch('name', nil)

      if group_name
        feature_service.add_group(group_name)
        status 201
        JSON.generate(group: { name: group_name })
      else
        fail InvalidParams, "Invalid parameters, required params are { 'group' => { 'name' => 'YOUR GROUP NAME' }  }"
      end
    end

    get '/v1/groups/:group_name/features' do |group_name|
      features = feature_service.get_group_features(group_name)
      JSON.generate(features: features.map(&:as_json))
    end

    post '/v1/groups/:group_name/features' do |group_name|
      feature_params = params.fetch('feature', {})
      feature_name   = feature_params['name']
      feature_desc   = feature_params['description']
      feature_enable = feature_params['enabled'] == 'true'

      if feature_name && feature_desc && !feature_enable.nil?
        args = { group: group_name, name: feature_name, description: feature_desc, enabled: feature_enable }
        feature = feature_service.add_feature(args)
        status 201
        JSON.generate(feature: feature.as_json)
      else
        fail InvalidParams, "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', 'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }"
      end
    end

    get '/v1/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      feature, warning = nil, nil

      begin
        feature = feature_service.get_feature(group_name, feature_name)
      rescue Bandiera::FeatureService::RecordNotFound => e
        thing = case e.message
                when /group/ then 'group'
                when /feature/ then 'feature'
                end

        feature = Bandiera::Feature.new(feature_name, group_name, nil, false)
        warning = "This #{thing} does not exist in the bandiera database."
      end

      data = { feature: feature.as_json }
      data[:warning] = warning if warning

      JSON.generate(data)
    end

    put '/v1/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      feature = feature_service.get_feature(group_name, feature_name)

      feature_params = params.fetch('feature', {})
      feature_group  = feature_params.fetch('group', group_name)
      feature_name   = feature_params['name']
      feature_desc   = feature_params['description']
      feature_enable = feature_params['enabled'] == 'true'

      if feature_name && feature_desc && !feature_enable.nil?
        args = { group: feature_group, name: feature_name, description: feature_desc, enabled: feature_enable }
        feature = feature_service.add_feature(args)
        status 200
        JSON.generate(feature: feature.as_json)
      else
        fail InvalidParams, "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', 'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }, optional params are { 'feature' => { 'group' => 'GROUP NAME' } }"
      end
    end

    get '/v1/all' do
      group_data = feature_service.get_groups.map do |group_name|
        {
          name: group_name,
          features: feature_service.get_group_features(group_name).map(&:as_json)
        }
      end

      JSON.generate(groups: group_data)
    end

    error Bandiera::FeatureService::RecordNotFound do
      status 404
      JSON.generate(error: request.env['sinatra.error'].message)
    end

    error InvalidParams do
      status 400
      JSON.generate(error: request.env['sinatra.error'].message)
    end
  end
end
