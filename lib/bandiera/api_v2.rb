module Bandiera
  class APIv2 < WebAppBase
    get '/all' do
      _get_all
    end

    def _get_all
      add_statsd_timer 'api.v2.all.get'

      group_map = {}
      warnings  = { user_group: [], user_id: [] }

      feature_service.fetch_groups.each do |group|
        features              = feature_service.fetch_group_features(group.name)
        flags, warnings       = build_features_hash(features, warnings)
        group_map[group.name] = flags
      end

      response           = { response: group_map }
      response[:warning] = format_multiple_warning_messages(warnings, true) if warnings_found?(warnings)

      json_or_jsonp(response)
    end

    get '/groups/:group_name/features' do |group_name|
      _get_group_features(group_name)
    end

    def _get_group_features(group_name)
      add_statsd_timer 'api.v2.group_features.get'

      response = { response: {} }

      begin
        features            = feature_service.fetch_group_features(group_name)
        flags, warnings     = build_features_hash(features)
        response[:response] = flags
        response[:warning]  = format_multiple_warning_messages(warnings) if warnings_found?(warnings)
      rescue Bandiera::FeatureService::GroupNotFound => e
        response[:warning] = e.message
      end

      json_or_jsonp(response)
    end

    get '/groups/:group_name/features/:feature_name' do |group_name, feature_name|
      _get_single_feature(group_name, feature_name)
    end

    def _get_single_feature(group_name, feature_name)
      add_statsd_timer 'api.v2.individual_feature.get'

      response = { response: false }

      begin
        feature  = feature_service.fetch_feature(group_name, feature_name)
        response = { response: response_for(feature) }

        warnings           = warnings_for(feature)
        response[:warning] = build_single_warning_reponse(warnings) if warnings.any?
      rescue Bandiera::FeatureService::FeatureNotFound, Bandiera::FeatureService::GroupNotFound => e
        response[:warning] = e.message
      end

      json_or_jsonp(response)
    end

    private

    def response_for(feature)
      feature.enabled?(user_group: params[:user_group], user_id: params[:user_id])
    end

    def warnings_for(feature)
      feature.report_enabled_warnings(user_group: params[:user_group], user_id: params[:user_id])
    end

    def build_single_warning_reponse(warnings)
      if warnings.include?(:user_group) && warnings.include?(:user_id)
        'This feature is configured for both user groups and percentages - you must supply both ' \
        '`user_group` and `user_id` params'
      elsif warnings.include?(:user_group)
        'This feature is configured for user groups - you must supply a `user_group` param'
      elsif warnings.include?(:user_id)
        'This feature is configured for user percentages - you must supply a `user_id` param'
      end
    end

    def build_features_hash(features, warning_map = { user_group: [], user_id: [] })
      response_map = {}

      features.each do |feature|
        response_map[feature.name] = response_for(feature)

        warnings_for(feature).each do |warning|
          warning_map[warning] << { name: feature.name, group: feature.group.name }
        end
      end

      [response_map, warning_map]
    end

    def warnings_found?(error_map)
      error_map[:user_group].any? || error_map[:user_id].any?
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
        user_group: 'these features have user groups configured and require a `user_group` param',
        user_id:    'these features have user percentages configured and require a `user_id` param'
      }

      msg << error_handles.map do |type, preamble|
        next if error_map[type].empty?

        features_with_warnings = names_for_warnings(error_map[type], show_group)

        "  * #{preamble}:\n" + features_with_warnings.map { |name| "    - #{name}\n" }.join
      end.join("\n")
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
