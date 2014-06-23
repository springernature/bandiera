require 'spec_helper'
require 'rack/test'

describe Bandiera::APIv2 do
  include Rack::Test::Methods

  def app
    Bandiera::APIv2
  end

  before do
    feature_service = Bandiera::FeatureService.new
    feature_service.add_features([
      { group: 'pubserv', name: 'show_subjects', description: '', active: true, user_groups: { list: ['editor'], regex: '' } },
      { group: 'pubserv', name: 'show_metrics', description: '', active: false },
      { group: 'pubserv', name: 'use_content_hub', description: '', active: true },
      { group: 'shunter', name: 'stats_logging', description: '', active: true }
    ])
  end

  describe 'GET /all' do
    it 'returns a 200 status' do
      get '/all'
      expect(last_response.status).to eq(200)
    end

    it 'returns a hash of groups, containing a hashes of features / enabled pairs' do
      expected_data = {
        'response' => {
          'pubserv' => {
            'show_subjects'   => false,
            'show_metrics'    => false,
            'use_content_hub' => true
          },
          'shunter' => {
            'stats_logging' => true
          }
        }
      }

      get '/all'
      assert_last_response_matches(expected_data)
    end

    context 'with the URL param "user_group" passed' do
      it 'passes this on to the feature when evaluating if a feature is enabled' do
        # this user_group statisfies the above settings - we expect show_subjects to be true
        get '/all', user_group: 'editor'
        expect(last_response_data['response']['pubserv']['show_subjects']).to be_truthy
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
        expected_data = {
          'response' => {
            'show_subjects' => false,
            'show_metrics' => false,
            'use_content_hub' => true
          }
        }

        get '/groups/pubserv/features'
        assert_last_response_matches(expected_data)
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
        expected_data = { 'response' => false }

        get '/groups/pubserv/features/show_subjects'
        assert_last_response_matches(expected_data)
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

  describe 'GET /groups/:group_name/features/:feature_name?user_id=ident' do
    context 'with user_id' do
      after :each do
        Bandiera::UserFeature.dataset.delete
      end

      context 'enabled feature with percentage' do
        before :each do
          feature_service = Bandiera::FeatureService.new
          feature = feature_service.get_feature('pubserv', 'use_content_hub')
          feature.percentage = percentage
          feature.save
        end

        context 'with 5%' do
          let(:percentage) { 5 }

          it 'it allow ~5% of the users to receive true' do
            expect(active_count(percentage)).to be < 15
          end
        end

        context 'with 95%' do
          let(:percentage) { 95 }

          it 'it allow ~95% of the users to receive true' do
            expect(active_count(percentage)).to be > 85
          end
        end
      end

      context 'disabled feature with percentage' do
        let(:percentage) { 95 }

        before :each do
          Bandiera::UserFeature.dataset.delete
          feature_service = Bandiera::FeatureService.new
          feature = feature_service.get_feature('pubserv', 'use_content_hub')
          feature.percentage = percentage
          feature.active     = false
          feature.save
        end

        it 'always return false' do
          expect(active_count(percentage)).to eq 0
        end
      end
    end

    context 'without user_id' do
      let(:percentage) { 95 }

      before :each do
        feature_service = Bandiera::FeatureService.new
        @feature = feature_service.get_feature('pubserv', 'use_content_hub')
        @feature.percentage = percentage
      end

      context 'enabled feature with percentage' do
        it 'always return false and send a warning' do
          @feature.active = true
          @feature.save

          get '/groups/pubserv/features/use_content_hub'
          @data = JSON.parse(last_response.body)
          expect(@data['response']).to eq(false)
          expect(@data['warning']).to_not be_nil
        end
      end

      context 'disabled feature with percentage' do
        it 'always return false' do
          @feature.active = false
          @feature.save

          get '/groups/pubserv/features/use_content_hub'
          @data = JSON.parse(last_response.body)
          expect(@data['response']).to eq(false)
          expect(@data['warning']).to be_nil
        end
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

  def active_count(percentage)
    @results = []
    (0...100).each do |i|
      get "/groups/pubserv/features/use_content_hub?user_id=user#{i}"
      @results << JSON.parse(last_response.body)['response']
    end
    @results.count { |v| v == true }
  end
end
