module Bandiera
  class APIv1 < WebAppBase
    get '/groups' do
      _get_groups
    end

    def _get_groups
      add_statsd_timer 'api.v1.groups.get'

      groups = feature_service.fetch_groups.map { |group| { name: group.name } }
      render_json(groups: groups)
    end

    post '/groups' do
      _post_groups
    end

    def _post_groups
      add_statsd_timer 'api.v1.groups.post'

      group_params = params.fetch('group', {})
      group_name   = group_params.fetch('name', nil)

      if group_name
        feature_service.add_group(group_name)
        status 201
        render_json(group: { name: group_name })
      else
        raise InvalidParams, "Invalid parameters, required params are { 'group' => { 'name' => 'YOUR GROUP NAME' }  }"
      end
    end

    get '/groups/:group_name/features' do |group_name|
      _get_group_features(group_name)
    end

    def _get_group_features(group_name)
      add_statsd_timer 'api.v1.group_features.get'

      features = feature_service.fetch_group_features(group_name)
      render_json(features: features.map(&:as_v1_json))
    end

    post '/groups/:group_name/features' do |group_name|
      _post_group_features(group_name)
    end

    def _post_group_features(group_name)
      add_statsd_timer 'api.v1.group_features.post'

      feature_params = process_v1_feature_params(params.fetch('feature', {}).merge('group' => group_name))

      with_valid_feature_params(feature_params) do
        feature = feature_service.add_feature(feature_params)
        status 201
        render_json(feature: feature.as_v1_json)
      end
    end

    get '/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      _get_individial_feature(group_name, feature_name)
    end

    def _get_individial_feature(group_name, feature_name)
      add_statsd_timer 'api.v1.individual_feature.get'

      data    = {}
      feature = nil

      begin
        feature = feature_service.fetch_feature(group_name, feature_name)
      rescue *[Bandiera::FeatureService::GroupNotFound, Bandiera::FeatureService::FeatureNotFound] => e
        feature        = Bandiera::Feature.stub_feature(feature_name, group_name)
        data[:warning] = e.message
      end

      data[:feature] = feature.as_v1_json

      render_json(data)
    end

    put '/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      _put_individial_feature(group_name, feature_name)
    end

    def _put_individial_feature(group_name, feature_name)
      add_statsd_timer 'api.v1.individual_feature.put'

      feature_params         = process_v1_feature_params(params.fetch('feature', {}))
      feature_params[:group] = group_name unless feature_params[:group]

      with_valid_feature_params(feature_params, true) do
        feature = feature_service.update_feature(group_name, feature_name, feature_params)
        status 200
        render_json(feature: feature.as_v1_json)
      end
    end

    get '/all' do
      _get_all
    end

    def _get_all
      add_statsd_timer 'api.v1.all.get'

      group_data = feature_service.fetch_groups.map do |group|
        {
          name:     group.name,
          features: feature_service.fetch_group_features(group.name).map(&:as_v1_json)
        }
      end

      render_json(groups: group_data)
    end

    error [Bandiera::FeatureService::GroupNotFound, Bandiera::FeatureService::FeatureNotFound] do
      status 404
      render_json(error: request.env['sinatra.error'].message)
    end

    error InvalidParams do
      status 400
      render_json(error: request.env['sinatra.error'].message)
    end

    private

    def render_json(data)
      data[:information] = 'You are using the v1 Bandiera API - this interface is deprecated, you should switch to use ' \
                     'the latest version (see https://github.com/springernature/bandiera/wiki/API-Documentation for more ' \
                     'information).'
      content_type :json
      JSON.generate(data)
    end

    def with_valid_feature_params(feature, inc_option_params_in_error = false)
      if valid_params?(feature)
        yield
      else
        error_msg = "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', " \
                    "'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }"
        error_msg << ", optional params are { 'feature' => { 'group' => 'GROUP NAME' } }" if inc_option_params_in_error
        raise InvalidParams, error_msg
      end
    end
  end
end
