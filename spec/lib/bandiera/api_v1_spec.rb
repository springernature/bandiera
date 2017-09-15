# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'

RSpec.describe Bandiera::APIv1 do
  include Rack::Test::Methods

  let(:instance) { Bandiera::APIv1 }
  let(:app) do
    app_instance = instance
    Rack::Builder.new do
      use Macmillan::Utils::StatsdMiddleware, client: Bandiera.statsd
      run Bandiera::APIv1
      run app_instance
    end
  end

  def assert_last_response_matches(expected_data)
    data = JSON.parse(last_response.body)
    data.delete('information') # this is the v1 API deprecation notice.
    expect(data).to eq(expected_data)
  end

  before do
    service = instance.settings.feature_service
    service.add_features([
                           { group: 'pubserv',   name: 'show_subjects',  description: 'Show all subject related features', active: false },
                           { group: 'pubserv',   name: 'show_search',    description: 'Show the search bar',               active: true  },
                           { group: 'pubserv',   name: 'xmas_mode',      description: 'Xmas mode: SNOWFLAKES!',            active: false },
                           { group: 'laserwolf', name: 'enable_caching', description: 'Enable caching',                    active: false },
                           { group: 'shunter',   name: 'stats_logging',  description: 'Log stats',                         active: true  }
                         ])
  end

  describe 'GET /groups' do
    before do
      get '/groups'
    end

    it 'returns a 200 status' do
      expect(last_response.status).to eq(200)
    end

    it 'returns an array of group names' do
      expected_data = {
        'groups' => [
          { 'name' => 'laserwolf' },
          { 'name' => 'pubserv' },
          { 'name' => 'shunter' }
        ]
      }

      assert_last_response_matches(expected_data)
    end
  end

  describe 'POST /groups' do
    context 'with valid params' do
      before do
        post '/groups', group: { name: 'wibble' }
      end

      it 'return status 200' do
        expect(last_response.status).to eq(201)
      end

      it 'creates a new group' do
        expected_data = { 'group' => { 'name' => 'wibble' } }

        assert_last_response_matches(expected_data)
      end
    end

    context 'with invalid params' do
      before do
        post '/groups', params: { wee: 'woo' }
      end

      it 'returns status 400' do
        expect(last_response.status).to eq(400)
      end

      it 'returns an error' do
        expected_data = {
          'error' => "Invalid parameters, required params are { 'group' => { 'name' => 'YOUR GROUP NAME' }  }"
        }

        assert_last_response_matches(expected_data)
      end
    end
  end

  describe 'GET /groups/:group_name/features' do
    context 'when the group exists' do
      before do
        get '/groups/shunter/features'
      end

      it 'returns status 200' do
        expect(last_response.status).to eq(200)
      end

      it 'returns an array of features for the group' do
        expected_data = {
          'features' => [{
            'group'       => 'shunter',
            'name'        => 'stats_logging',
            'description' => 'Log stats',
            'enabled'     => true
          }]
        }

        assert_last_response_matches(expected_data)
      end
    end

    context "when the group doesn't exist" do
      before do
        get '/groups/non_existent/features'
      end

      it 'returns a 404' do
        expect(last_response.status).to eq(404)
      end

      it 'returns error data' do
        expected_data = {
          'error' => 'This group does not exist in the Bandiera database.'
        }

        assert_last_response_matches(expected_data)
      end
    end
  end

  describe 'POST /groups/:group_name/features' do
    context 'when the group exists' do
      context 'with valid params' do
        let(:feature_params) do
          {
            'name'        => 'new_feature',
            'description' => 'A new new feature',
            'enabled'     => false
          }
        end

        before do
          post '/groups/shunter/features', feature: feature_params
        end

        it 'returns a 201 status' do
          expect(last_response.status).to eq(201)
        end

        it 'creates a new feature for the group' do
          expected_data = { 'feature' => feature_params.merge('group' => 'shunter') }

          assert_last_response_matches(expected_data)
        end
      end

      context 'with invalid params' do
        let(:feature_params) do
          { 'feature_name' => 'new_feature', 'enabled' => true }
        end

        before do
          post '/groups/shunter/features', feature: feature_params
        end

        it 'returns a 400 status code' do
          expect(last_response.status).to eq(400)
        end

        it 'returns an error' do
          expected_data = {
            'error' => "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', " \
                       "'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }"
          }

          assert_last_response_matches(expected_data)
        end
      end
    end

    context "when the group doesn't exist" do
      let(:feature_params) do
        {
          'name'        => 'test-feature',
          'description' => 'A NEW TEST FEATURE',
          'enabled'     => false
        }
      end

      before do
        post '/groups/wibble/features', feature: feature_params
      end

      it 'returns a 201 status code' do
        expect(last_response.status).to eq(201)
      end

      it 'creates the group and the new feature' do
        expected_data = { 'feature' => feature_params.merge('group' => 'wibble') }

        assert_last_response_matches(expected_data)
      end
    end
  end

  describe 'GET /groups/:group_name/features/:feature_name' do
    context 'when both the group and the feature exists' do
      before do
        get '/groups/pubserv/features/show_search'
      end

      it 'returns a 200 status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the feature' do
        expected_data = {
          'feature' => {
            'group'       => 'pubserv',
            'name'        => 'show_search',
            'description' => 'Show the search bar',
            'enabled'     => true
          }
        }

        assert_last_response_matches(expected_data)
      end
    end

    context "when the group doesn't exist" do
      before do
        get '/groups/non_existent/features/wibble'
      end

      it 'returns a 200 status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns a valid feature object, but set to false (with a warning message)' do
        expected_data = {
          'feature' => {
            'group'       => 'non_existent',
            'name'        => 'wibble',
            'description' => '',
            'enabled'     => false
          },
          'warning' => 'This group does not exist in the Bandiera database.'
        }

        assert_last_response_matches(expected_data)
      end
    end

    context "when the group exists, but the feature doesn't" do
      before do
        get '/groups/laserwolf/features/non_existent'
      end

      it 'returns a 200 status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns a valid feature object, but set to false (with a warning message)' do
        expected_data = {
          'feature' => {
            'group'       => 'laserwolf',
            'name'        => 'non_existent',
            'description' => '',
            'enabled'     => false
          },
          'warning' => 'This feature does not exist in the Bandiera database.'
        }

        assert_last_response_matches(expected_data)
      end
    end
  end

  describe 'PUT /groups/:group_name/features/:feature_name' do
    context 'when both the group and the feature exists' do
      context 'with valid params' do
        it 'updates the feature' do
          get '/groups/shunter/features/stats_logging'

          feature = JSON.parse(last_response.body)['feature']

          put '/groups/shunter/features/stats_logging',
            feature: feature.merge('group' => 'laserwolf', 'enabled' => 'false')

          expect(last_response).to be_successful

          get '/groups/laserwolf/features/stats_logging'

          updated_feature = JSON.parse(last_response.body)['feature']

          expect(feature).to_not eq(updated_feature)
        end
      end

      context 'with invalid params' do
        let(:feature_params) do
          { 'feature_name' => 'new_feature_name' }
        end

        before do
          put '/groups/shunter/features/stats_logging', feature: feature_params
        end

        it 'returns a 400 status code' do
          expect(last_response.status).to eq(400)
        end

        it 'returns an error' do
          expected_data = {
            'error' => "Invalid parameters, required params are { 'feature' => { 'name' => 'FEATURE NAME', " \
                       "'description' => 'FEATURE DESCRIPTION', 'enabled' => 'TRUE OR FALSE' }  }, optional " \
                       "params are { 'feature' => { 'group' => 'GROUP NAME' } }"
          }

          assert_last_response_matches(expected_data)
        end
      end
    end

    context 'when the' do
      let(:params) do
        {
          feature: {
            name:        'wibble_logging',
            description: 'Log me some wibble',
            enabled:     true
          }
        }
      end

      context "group doesn't exist" do
        it 'returns a 404' do
          put '/groups/wibble/features/wibble_logging', params
          expect(last_response.status).to eq(404)
        end
      end

      context "feature doesn't exist" do
        it 'returns a 404' do
          put '/groups/shunter/features/wibble_logging', params
          expect(last_response.status).to eq(404)
        end
      end
    end
  end

  describe 'GET /all' do
    let(:expected_data) do
      {
        'groups' => [
          {
            'name'     => 'laserwolf',
            'features' => [
              {
                'group'       => 'laserwolf',
                'name'        => 'enable_caching',
                'description' => 'Enable caching',
                'enabled'     => false
              }
            ]
          },
          {
            'name'     => 'pubserv',
            'features' => [
              {
                'group'       => 'pubserv',
                'name'        => 'show_search',
                'description' => 'Show the search bar',
                'enabled'     => true
              },
              {
                'group'       => 'pubserv',
                'name'        => 'show_subjects',
                'description' => 'Show all subject related features',
                'enabled'     => false
              },
              {
                'group'       => 'pubserv',
                'name'        => 'xmas_mode',
                'description' => 'Xmas mode: SNOWFLAKES!',
                'enabled'     => false
              }
            ]
          },
          {
            'name'     => 'shunter',
            'features' => [
              { 'group' => 'shunter', 'name' => 'stats_logging', 'description' => 'Log stats', 'enabled' => true }
            ]
          }
        ]
      }
    end

    before do
      get '/all'
    end

    it 'returns a 200 status code' do
      expect(last_response.status).to eq(200)
    end

    it 'returns all features in the database grouped by group' do
      data = JSON.parse(last_response.body)

      data['groups'].each_index do |index|
        fetched  = data['groups'][index]
        expected = expected_data['groups'][index]

        expect(fetched['name']).to eq(expected['name'])
        expect(fetched['features']).to match_array(expected['features'])
      end
    end
  end
end
