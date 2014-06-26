module Bandiera
  class APIv2 < WebAppBase
    get '/all' do
      group_map = {}

      feature_service.get_groups.each do |group|
        features = feature_service.get_group_features(group.name)
        group_map[group.name] = features_enabled_hash(features)
      end

      json_or_jsonp(response: group_map)
    end

    get '/groups/:group_name/features' do |group_name|
      response = { response: features_enabled_hash([]) }

      begin
        features            = feature_service.get_group_features(group_name)
        response[:response] = features_enabled_hash(features)
      rescue Bandiera::FeatureService::GroupNotFound => e
        response[:warning] = e.message
      end

      json_or_jsonp(response)
    end

    get '/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      begin
        feature  = feature_service.get_feature(group_name, feature_name)
        response = response_for(feature)
      rescue *
        [
          Bandiera::FeatureService::GroupNotFound,
          Bandiera::FeatureService::FeatureNotFound,
          Bandiera::FeatureService::UserNotFound
        ] => e
        response = { response: false, warning:  e.message }
      end
      json_or_jsonp(response)
    end

    private

    def response_for(feature)
      if feature.percentage
        { response: feature_service.user_within_percentage?(params[:user_id], feature) }
      else
        { response: feature.enabled?(user_group: params[:user_group]) }
      end
    end

    def features_enabled_hash(features)
      map = {}

      features.each do |feature|
        map[feature.name] = feature.enabled?(user_group: params[:user_group])
      end

      map
    end

    def json_or_jsonp(data)
      callback = params.delete('callback')
      json     = JSON.generate(data)

      if callback
        content_type :js
        "#{callback}(#{json})"
      else
        content_type :json
        json
      end
    end
  end
end
