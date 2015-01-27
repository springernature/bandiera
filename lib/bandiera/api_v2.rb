module Bandiera
  class APIv2 < WebAppBase
    get '/all' do
      add_statsd_timer 'api.v2.all.get'

      group_map = {}
      warnings  = { user_group: [], user_percentage: [] }

      feature_service.get_groups.each do |group|
        features              = feature_service.get_group_features(group.name)
        flags, warnings       = build_features_hash(features, warnings)
        group_map[group.name] = flags
      end

      response           = { response: group_map }
      response[:warning] = format_multiple_warning_messages(warnings, true) if warnings_found?(warnings)

      json_or_jsonp(response)
    end

    get '/groups/:group_name/features' do |group_name|
      add_statsd_timer 'api.v2.group_features.get'

      response = { response: {} }

      begin
        features            = feature_service.get_group_features(group_name)
        flags, warnings     = build_features_hash(features)
        response[:response] = flags
        response[:warning]  = format_multiple_warning_messages(warnings) if warnings_found?(warnings)
      rescue Bandiera::FeatureService::GroupNotFound => e
        response[:warning] = e.message
      end

      json_or_jsonp(response)
    end

    get '/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      add_statsd_timer 'api.v2.individual_feature.get'

      begin
        feature  = feature_service.get_feature(group_name, feature_name)
        response = { response: response_for(feature) }
      rescue *
        [
          Bandiera::FeatureService::GroupNotFound,
          Bandiera::FeatureService::FeatureNotFound,
          Bandiera::Feature::UserGroupArgumentError,
          Bandiera::Feature::UserPercentageArgumentError
        ] => e
        response = { response: false, warning:  e.message }
      end

      json_or_jsonp(response)
    end

    private

    def response_for(feature)
      feature.enabled?(user_group: params[:user_group], user_id: params[:user_id])
    end

    def build_features_hash(features, error_map = { user_group: [], user_percentage: [] })
      response_map = {}

      features.each do |feature|
        begin
          response_map[feature.name] = response_for(feature)
        rescue *[Bandiera::Feature::UserGroupArgumentError, Bandiera::Feature::UserPercentageArgumentError] => e
          map_key = case e
                    when Bandiera::Feature::UserGroupArgumentError      then :user_group
                    when Bandiera::Feature::UserPercentageArgumentError then :user_percentage
                    end

          response_map[feature.name] = false
          error_map[map_key] << { name: feature.name, group: feature.group.name }
        end
      end

      [response_map, error_map]
    end

    def warnings_found?(error_map)
      error_map[:user_group].any? || error_map[:user_percentage].any?
    end

    def names_for_warnings(warnings, show_group)
      warnings.map do |warn|
        strings = []
        strings << warn[:group] if show_group
        strings << warn[:name]
        strings.join(': ')
      end
    end

    def format_multiple_warning_messages(error_map, show_group = false)
      msg           = "The following warnings were raised on this request:\n"
      error_handles = {
        user_group:       "these features have user groups configured and require a `user_group` param",
        user_percentage:  "these features have user percentages configured and require a `user_id` param"
      }

      error_handles.each do |type, preamble|
        next if error_map[type].empty?

        features_with_warnings = names_for_warnings(error_map[type], show_group)

        msg << "  * #{preamble}:\n"
        msg << features_with_warnings.map { |name| "    - #{name}\n" }.join
        msg << "\n"
      end

      msg
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
