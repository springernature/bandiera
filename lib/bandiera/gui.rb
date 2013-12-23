require "sinatra/base"

module Bandiera
  class GUI < Sinatra::Base
    set :root, Proc.new { File.join( File.dirname(__FILE__), 'gui' ) }

    helpers do
      def feature_service
        @feature_service ||= FeatureService.new
      end
    end

    get "/" do
      @groups_and_features = feature_service.get_groups.map do |group_name|
        { name: group_name, features: feature_service.get_group_features(group_name) }
      end

      erb :index
    end
  end
end
