# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'

RSpec.describe Bandiera::APIv2 do
  include Rack::Test::Methods

  let(:instance) { Bandiera::APIv2 }
  let(:app) do
    app_instance = instance
    Rack::Builder.new do
      use Macmillan::Utils::StatsdMiddleware, client: Bandiera.statsd
      run Bandiera::APIv2
      run app_instance
    end
  end

  def app
    Rack::Builder.new do
      use Macmillan::Utils::StatsdMiddleware, client: Bandiera.statsd
      run Bandiera::APIv2
    end
  end

  before do
    service = instance.settings.feature_service
    service.add_features([
                           { group: 'pubserv',    name: 'show_subjects',   description: '', active: true, user_groups: { list: ['editor'], regex: '' } },
                           { group: 'pubserv',    name: 'show_metrics',    description: '', active: false },
                           { group: 'pubserv',    name: 'use_content_hub', description: '', active: true },
                           { group: 'shunter',    name: 'stats_logging',   description: '', active: true },
                           { group: 'shunter',    name: 'use_img_serv',    description: '', active: true, percentage: 50 },
                           { group: 'parliament', name: 'in_dissolution',  description: '', active: true, start_time: Time.now - 100, end_time: Time.now + 100 },
                           { group: 'parliament', name: 'show_search',     description: '', active: true, start_time: Time.now + 100, end_time: Time.now + 200 }
                         ])
  end

  describe 'GET /all' do
    it 'returns a 200 status' do
      get '/all'
      expect(last_response.status).to eq(200)
    end

    it 'returns a hash of groups, containing a hashes of features / enabled pairs' do
      expected_response = {
        'pubserv'    => {
          'show_subjects'   => false,
          'show_metrics'    => false,
          'use_content_hub' => true
        },
        'shunter'    => {
          'stats_logging' => true,
          'use_img_serv'  => false
        },
        'parliament' => {
          'in_dissolution' => true,
          'show_search'    => false
        }
      }

      get '/all'
      expect(last_response_data['response']).to eq expected_response
    end

    it 'returns a warning if the correct params are not passed when there are user_group or percentage features' do
      get '/all'
      expect(last_response_data['warning']).to_not be_nil

      get '/all', user_group: 'wibble', user_id: 12_345
      expect(last_response_data['warning']).to be_nil
    end

    context 'with the URL param "user_group" passed' do
      it 'passes this on to the feature when evaluating if a feature is enabled' do
        # this user_group statisfies the above settings - we expect show_subjects to be true
        get '/all', user_group: 'editor'
        expect(last_response_data['response']['pubserv']['show_subjects']).to eq true
      end
    end
  end

  describe 'GET /groups/:group_name/features' do
    it 'returns a 200 status' do
      get '/groups/pubserv/features'
      expect(last_response.status).to eq(200)
    end

    context 'when the group exists' do
      it 'returns a hash of features / enabled pairs' do
        expected_response = {
          'show_subjects'   => false,
          'show_metrics'    => false,
          'use_content_hub' => true
        }

        get '/groups/pubserv/features'
        expect(last_response_data['response']).to eq expected_response
      end

      it 'returns a warning if the correct params are not passed when there are user_group or percentage features' do
        get '/groups/pubserv/features'
        expect(last_response_data['warning']).to_not be_nil

        get '/groups/pubserv/features', user_group: 'wibble', user_id: 12_345
        expect(last_response_data['warning']).to be_nil
      end

      context 'with the URL param "user_group" passed' do
        it 'passes this on to the feature when evaluating if a feature is enabled' do
          # this user_group statisfies the above settings - we expect show_subjects to be true
          get '/groups/pubserv/features', user_group: 'editor'
          expect(last_response_data['response']['show_subjects']).to be_truthy
        end
      end
    end

    context 'when the group does not exist' do
      before do
        get '/groups/wibble/features'
        @data = JSON.parse(last_response.body)
      end

      it 'returns a 200 status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns an empty data hash' do
        expect(@data['response']).to eq({})
      end

      it 'returns a warning' do
        expect(@data['warning']).to_not be_nil
        expect(@data['warning']).to_not be_empty
      end
    end
  end

  describe 'GET /groups/:group_name/features/:feature_name' do
    it 'returns a 200 status' do
      get '/groups/pubserv/features/show_subjects'
      expect(last_response.status).to eq(200)
    end

    context 'when both the group and feature exist' do
      it 'returns a boolean representing the enabled status' do
        expected_data = { 'response' => true }

        get '/groups/pubserv/features/use_content_hub'
        assert_last_response_matches(expected_data)
      end

      it 'returns a warning if correct params are not passed when the feature is a user_group/percentage feature' do
        get '/groups/pubserv/features/show_subjects'
        expect(last_response_data['warning']).to_not be_nil

        get '/groups/pubserv/features/show_subjects', user_group: 'wibble'
        expect(last_response_data['warning']).to be_nil

        get '/groups/shunter/features/use_img_serv'
        expect(last_response_data['warning']).to_not be_nil

        get '/groups/shunter/features/use_img_serv', user_id: 12_345
        expect(last_response_data['warning']).to be_nil
      end

      context 'with the URL param "user_group" passed' do
        it 'passes this on to the feature when evaluating if a feature is enabled' do
          # this user_group statisfies the above settings - we expect show_subjects to be true
          get '/groups/pubserv/features/show_subjects', user_group: 'editor'
          expect(last_response_data['response']).to be_truthy
        end
      end
    end

    context 'when the group does not exist' do
      before do
        get '/groups/wibble/features/wobble'
        @data = JSON.parse(last_response.body)
      end

      it 'returns a 200 status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns a "false" flag value' do
        expect(@data['response']).to eq(false)
      end

      it 'returns a warning' do
        expect(@data['warning']).to_not be_nil
        expect(@data['warning']).to_not be_empty
      end
    end

    context 'when the feature does not exist' do
      before do
        get '/groups/pubserv/features/wobble'
        @data = JSON.parse(last_response.body)
      end

      it 'returns a 200 status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns a "false" flag value' do
        expect(@data['response']).to eq(false)
      end

      it 'returns a warning' do
        expect(@data['warning']).to_not be_nil
        expect(@data['warning']).to_not be_empty
      end
    end
  end

  private

  def last_response_data
    JSON.parse(last_response.body)
  end

  def assert_last_response_matches(expected_data)
    expect(last_response_data).to eq(expected_data)
  end
end
