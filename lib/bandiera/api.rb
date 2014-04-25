module Bandiera
  class API < WebAppBase
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
      JSON.generate(features: features.map(&:as_v1_json))
    end

    post '/v1/groups/:group_name/features' do |group_name|
      feature_params = process_v1_feature_params(params.fetch('feature', {}).merge('group' => group_name))

      with_valid_feature_params(feature_params) do
        feature = feature_service.add_feature(feature_params)
        status 201
        JSON.generate(feature: feature.as_v1_json)
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

      data = { feature: feature.as_v1_json }
      data[:warning] = warning if warning

      JSON.generate(data)
    end

    put '/v1/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      feature_params         = process_v1_feature_params(params.fetch('feature', {}))
      feature_params[:group] = group_name unless feature_params[:group]

      with_valid_feature_params(feature_params, true) do
        feature = feature_service.update_feature(group_name, feature_name, feature_params)
        status 200
        JSON.generate(feature: feature.as_v1_json)
      end
    end

    get '/v1/all' do
      group_data = feature_service.get_groups.map do |group_name|
        {
          name: group_name,
          features: feature_service.get_group_features(group_name).map(&:as_v1_json)
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

    private

    def with_valid_feature_params(feature, include_option_params_in_error_msg=false)
      if valid_params?(feature)
        yield
      else
        error_msg = "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', 'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }"
        error_msg << ", optional params are { 'feature' => { 'group' => 'GROUP NAME' } }" if include_option_params_in_error_msg
        fail InvalidParams, error_msg
      end
    end
  end
end
