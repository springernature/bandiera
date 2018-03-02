require 'rack-flash'
require 'tilt/erubis'

module Bandiera
  class GUI < WebAppBase
    configure do
      set :root, File.join(File.dirname(__FILE__), 'gui')
      set :erb, escape_html: true
      enable :sessions
    end

    helpers do
      def partial(template, locals = {})
        erb(template, layout: false, locals: locals)
      end
    end

    use Rack::Flash

    error Bandiera::FeatureService::GroupNotFound do
      not_found
    end

    error Bandiera::FeatureService::FeatureNotFound do
      not_found
    end

    get '/' do
      _get_home
    end

    def _get_home
      @groups_and_features = feature_service.fetch_groups.map do |group|
        { name: group.name, features: feature_service.fetch_group_features(group.name) }
      end

      erb :index
    end

    # Groups.

    get '/new/group' do
      _get_new_group
    end

    def _get_new_group
      erb :new_group
    end

    post '/create/group' do
      _post_create_group
    end

    def _post_create_group
      group_name = params[:group][:name]

      with_valid_group_params(group_name, '/new/group') do
        feature_service.add_group(audit_context, group_name)
        flash[:success] = 'Group created.'
        redirect '/'
      end
    end

    # Features

    get '/new/feature' do
      _get_new_feature
    end

    def _get_new_feature
      @groups = feature_service.fetch_groups

      erb :new_feature
    end

    post '/create/feature' do
      _post_create_feature
    end

    def _post_create_feature
      feature = process_v2_feature_params(params[:feature])

      with_valid_feature_params(feature, '/new/feature') do
        feature_service.add_feature(audit_context, feature)
        flash[:success] = 'Feature created.'
        redirect '/'
      end
    end

    get '/groups/:group_name/features/:feature_name/edit' do |group_name, feature_name|
      _get_edit_feature(group_name, feature_name)
    end

    def _get_edit_feature(group_name, feature_name)
      @groups  = feature_service.fetch_groups
      @feature = feature_service.fetch_feature(group_name, feature_name)

      erb :edit_feature
    end

    post '/update/feature' do
      _post_update_feature
    end

    def _post_update_feature
      prev_group  = params[:feature][:previous_group]
      prev_name   = params[:feature][:previous_name]
      new_feature = process_v2_feature_params(params[:feature])

      with_valid_feature_params(new_feature, "/groups/#{prev_group}/features/#{prev_name}/edit") do
        feature_service.update_feature(audit_context, prev_group, prev_name, new_feature)
        flash[:success] = 'Feature updated.'
        redirect '/'
      end
    end

    put '/update/feature/active_toggle' do
      _put_update_feature_active_toggle
    end

    def _put_update_feature_active_toggle
      feat_params = params[:feature] || {}
      group       = feat_params[:group]
      name        = feat_params[:name]
      active      = feat_params[:active] == 'true'

      if group && name && !active.nil?
        feature_service.update_feature(audit_context, group, name, { active: active })
        status 200
        content_type :json
        '{}'
      else
        status 401
        halt
      end
    end

    get '/groups/:group_name/features/:feature_name/delete' do |group_name, feature_name|
      _get_delete_feature(group_name, feature_name)
    end

    def _get_delete_feature(group_name, feature_name)
      feature_service.remove_feature(audit_context, group_name, feature_name)
      flash[:success] = 'Feature deleted.'
      redirect '/'
    end

    private

    def with_valid_feature_params(feature, on_error_url)
      if valid_feature_params?(feature)
        yield
      else
        errors = []
        errors << 'enter a feature name' unless param_present?(feature[:name])
        errors << 'enter a feature name without spaces' if param_has_whitespace?(feature[:name])
        errors << 'select a group' unless param_present?(feature[:group])
        errors << 'enter an end time if you enter a start time' if param_present?(feature[:start_time]) && !param_present?(feature[:end_time])
        errors << 'enter a start time if you enter an end time' if param_present?(feature[:end_time]) && !param_present?(feature[:start_time])
        errors << 'enter an end time that is after your start time' if param_present?(feature[:end_time]) &&  param_present?(feature[:start_time]) && !times_in_order?(feature[:start_time], feature[:end_time])
        flash[:danger] = "You must #{errors.join(' and ')}."
        redirect on_error_url
      end
    end

    def with_valid_group_params(group_name, on_error_url)
      if param_present?(group_name) && !param_has_whitespace?(group_name)
        yield
      else
        errors = []
        errors << 'enter a group name' unless param_present?(group_name)
        errors << 'enter a group name without spaces' if param_has_whitespace?(group_name)
        flash[:danger] = "You must #{errors.join(' and ')}."
        redirect on_error_url
      end
    end
  end
end
