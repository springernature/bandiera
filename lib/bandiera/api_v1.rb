module Bandiera
  class APIv1 < WebAppBase
    before do
      content_type :json
    end

    get '/groups' do
      groups = feature_service.get_groups.map { |name| { name: name } }
      render_json(groups: groups)
    end

    post '/groups' do
      group_params = params.fetch('group', {})
      group_name   = group_params.fetch('name', nil)

      if group_name
        feature_service.add_group(group_name)
        status 201
        render_json(group: { name: group_name })
      else
        fail InvalidParams, "Invalid parameters, required params are { 'group' => { 'name' => 'YOUR GROUP NAME' }  }"
      end
    end

    get '/groups/:group_name/features' do |group_name|
      features = feature_service.get_group_features(group_name)
      render_json(features: features.map(&:as_v1_json))
    end

    post '/groups/:group_name/features' do |group_name|
      feature_params = process_v1_feature_params(params.fetch('feature', {}).merge('group' => group_name))

      with_valid_feature_params(feature_params) do
        feature = feature_service.add_feature(feature_params)
        status 201
        render_json(feature: feature.as_v1_json)
      end
    end

    get '/groups/:group_name/features/:feature_name' do |group_name, feature_name|
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

      render_json(data)
    end

    put '/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      feature_params         = process_v1_feature_params(params.fetch('feature', {}))
      feature_params[:group] = group_name unless feature_params[:group]

      with_valid_feature_params(feature_params, true) do
        feature = feature_service.update_feature(group_name, feature_name, feature_params)
        status 200
        render_json(feature: feature.as_v1_json)
      end
    end

    get '/all' do
      group_data = feature_service.get_groups.map do |group_name|
        {
          name: group_name,
          features: feature_service.get_group_features(group_name).map(&:as_v1_json)
        }
      end

      render_json(groups: group_data)
    end

    error Bandiera::FeatureService::RecordNotFound do
      status 404
      render_json(error: request.env['sinatra.error'].message)
    end

    error InvalidParams do
      status 400
      render_json(error: request.env['sinatra.error'].message)
    end

    private

    def render_json(data)
      data.merge!(information: "You are using the v1 Bandiera API - this interface is deprecated, you should switch to use the latest version (see GITHUB_URL for more information).")
      JSON.generate(data)
    end

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
