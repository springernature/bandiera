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
        return { response: false } unless feature
        response = response_for(feature)
      rescue *[Bandiera::FeatureService::GroupNotFound, Bandiera::FeatureService::FeatureNotFound] => e
        response = { response: false, warning:  e.message }
      end
      json_or_jsonp(response)
    end

    private

    def response_for(feature)
      if feature.percentage
        feature_percentage(feature)
      else
        { response: feature_enabled?(feature) }
      end
    end

    def feature_percentage(feature)
      if !feature.active?
        { response: false }
      elsif !params[:user_id]
        { response: false, warning:  "Feature is only active for a percentage of users. You need to pass a user id." }
      else
        user_feature  = feature_service.get_user_feature(params[:user_id], feature.id)
        { response: feature_enabled_for_user?(feature, user_feature) }
      end
    end

    def current_user_group
      params[:user_group]
    end

    def feature_enabled?(feature)
      feature.enabled?(user_group: current_user_group)
    end

    def feature_enabled_for_user?(feature, user_feature)
      feature_enabled?(feature) && feature.enabled_for_user?(user_feature)
    end

    def features_enabled_hash(features)
      map = {}

      features.each do |feature|
        map[feature.name] = feature_enabled?(feature)
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
