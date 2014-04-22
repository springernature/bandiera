require 'sinatra/base'
require 'rack-flash'

module Bandiera
  class GUI < Sinatra::Base
    configure do
      set :root, File.join(File.dirname(__FILE__), 'gui')

      enable :sessions
      enable :logging
    end

    use Rack::Flash

    helpers do
      def feature_service
        @feature_service ||= FeatureService.new
      end

      def logger
        env['bandiera-logger']
      end
    end

    get '/' do
      @groups_and_features = feature_service.get_groups.map do |group_name|
        { name: group_name, features: feature_service.get_group_features(group_name) }
      end

      erb :index
    end

    # Groups.

    get '/new/group' do
      erb :new_group
    end

    post '/create/group' do
      group_name = params[:group][:name]

      if param_present?(group_name)
        feature_service.add_group(group_name)
        flash[:success] = 'Group created.'
        redirect '/'
      else
        flash[:danger] = 'You must enter a group name.'
        redirect '/new/group'
      end
    end

    # Features.

    get '/new/feature' do
      @groups = feature_service.get_groups

      erb :new_feature
    end

    post '/create/feature' do
      feature = setup_feature_params(params[:feature])

      with_valid_feature_params(feature, '/new/feature') do
        feature_service.add_feature(feature)
        flash[:success] = 'Feature created.'
        redirect '/'
      end
    end

    get '/groups/:group_name/features/:feature_name/edit' do |group_name, feature_name|
      @groups  = feature_service.get_groups
      @feature = feature_service.get_feature(group_name, feature_name)

      erb :edit_feature
    end

    post '/update/feature' do
      prev_group  = params[:feature][:previous_group]
      prev_name   = params[:feature][:previous_name]
      new_feature = setup_feature_params(params[:feature])

      with_valid_feature_params(new_feature, "/groups/#{prev_group}/features/#{prev_name}/edit") do
        feature_service.update_feature(prev_group, prev_name, new_feature)
        flash[:success] = 'Feature updated.'
        redirect '/'
      end
    end

    get '/groups/:group_name/features/:feature_name/delete' do |group_name, feature_name|
      feature_service.remove_feature(group_name, feature_name)
      flash[:success] = 'Feature deleted.'
      redirect '/'
    end

    private

    def setup_feature_params(feature_params)
      {
        group:        feature_params[:group],
        name:         feature_params[:name],
        description:  feature_params[:description],
        enabled:      feature_params[:enabled] == 'true'
      }
    end

    def with_valid_feature_params(feature, on_error_url, &block)
      if param_present?(feature[:name]) && param_present?(feature[:group]) && !feature[:name].include?(' ')
        yield
      else
        errors = []
        errors << 'enter a feature name' unless param_present?(feature[:name])
        errors << 'enter a feature name without spaces' if feature[:name].include?(' ')
        errors << 'select a group' unless param_present?(feature[:group])
        flash[:danger] = "You must #{errors.join(" and ")}."
        redirect on_error_url
      end
    end

    def param_present?(param)
      param && !param.empty?
    end
  end
end
