require 'spec_helper'

RSpec.describe Bandiera::CachingFeatureService do
  let(:delegate) {instance_double('FeatureService')}
  let(:clock) {class_double('Time')}
  let(:now) {1270968656}
  let(:cache_time) {10}
  let(:group) {Bandiera::Group.new(name: 'group1')}
  let(:groups) {[Bandiera::Group.new(name: 'group1')]}
  let(:feature) {Bandiera::Feature.new(name: 'feature1')}
  let(:features) {[Bandiera::Feature.new(name: 'feature1'),
                   Bandiera::Feature.new(name: 'feature2')]}

  subject {Bandiera::CachingFeatureService.new(delegate, clock)}

  before do
    allow(clock).to receive(:now).and_return(now)
  end

  describe '#add_group' do
    it 'adds the group to the delegate' do
      expect(delegate).to receive(:add_group).with('burgers').and_return(group)

      result = subject.add_group('burgers')
      expect(result).to eq(group)
    end

    it 'invalidates the groups cache' do
      expect(delegate).to receive(:fetch_groups).twice.and_return(groups)
      allow(delegate).to receive(:add_group).with('burgers')

      subject.fetch_groups

      subject.add_group('burgers')

      subject.fetch_groups
    end

    it 'invalidates the groups by name cache' do
      expect(delegate).to receive(:find_group).twice.and_return(group)
      allow(delegate).to receive(:add_group).with('burgers')

      subject.find_group('group1')

      subject.add_group('burgers')

      subject.find_group('group1')
    end
  end

  describe '#fetch_groups' do
    it 'gets a array of all group objects from the delegate' do
      expect(delegate).to receive(:fetch_groups).and_return(groups)

      result = subject.fetch_groups

      expect(result.first).to be_an_instance_of(Bandiera::Group)
      expect(result.first.name).to eq('group1')
    end

    it 'caches subsequent calls' do
      expect(delegate).to receive(:fetch_groups).and_return(groups)

      subject.fetch_groups

      result = subject.fetch_groups

      expect(result.first).to be_an_instance_of(Bandiera::Group)
      expect(result.first.name).to eq('group1')
    end

    it 'does not cache errors' do
      call_count = 0
      allow(delegate).to receive(:fetch_groups) do
        call_count += 1
        call_count == 1 ? raise(SocketError.new) : groups
      end

      expect {subject.fetch_groups}.to raise_error(SocketError)

      result = subject.fetch_groups
      expect(result.first).to be_an_instance_of(Bandiera::Group)
      expect(result.first.name).to eq('group1')
      expect(call_count).to eq(2)
    end

    it 'serves from the cache up to the cached time' do
      expect(delegate).to receive(:fetch_groups).and_return(groups)

      subject.fetch_groups

      allow(clock).to receive(:now).and_return(now + cache_time - 1)
      subject.fetch_groups
    end

    it 'expires the cache after the cache time' do
      expect(delegate).to receive(:fetch_groups).twice.and_return(groups)

      subject.fetch_groups
      allow(clock).to receive(:now).and_return(now + cache_time)
      subject.fetch_groups
    end
  end

  describe '#find_group' do
    let(:another_group) {Bandiera::Group.new(name: 'group2')}

    it 'gets a group from the delegate' do
      expect(delegate).to receive(:find_group).with('group1').and_return(group)

      result = subject.find_group('group1')

      expect(result).to be_an_instance_of(Bandiera::Group)
      expect(result.name).to eq('group1')
    end

    it 'caches subsequent calls' do
      expect(delegate).to receive(:find_group).with('group1').and_return(group)

      subject.find_group('group1')

      result = subject.find_group('group1')

      expect(result).to be_an_instance_of(Bandiera::Group)
      expect(result.name).to eq('group1')
    end

    it 'does not cache errors' do
      call_count = 0
      allow(delegate).to receive(:find_group) do
        call_count += 1
        call_count == 1 ? raise(Bandiera::FeatureService::GroupNotFound.new) : group
      end

      expect {subject.find_group('group1')}.to raise_error(Bandiera::FeatureService::GroupNotFound)

      result = subject.find_group('group1')
      expect(result).to be_an_instance_of(Bandiera::Group)
      expect(result.name).to eq('group1')
      expect(call_count).to eq(2)
    end

    it 'does not share the cache expiry between keys' do
      expect(delegate).to receive(:find_group).with('group1').twice.and_return(group)
      expect(delegate).to receive(:find_group).with('group2').and_return(another_group)

      subject.find_group('group1')
      allow(clock).to receive(:now).and_return(now + (cache_time - 1))
      subject.find_group('group2')

      allow(clock).to receive(:now).and_return(now + cache_time)
      subject.find_group('group1')
      subject.find_group('group2')
    end

    it 'serves from the cache up to the cached time' do
      expect(delegate).to receive(:find_group).with('group1').and_return(group)

      subject.find_group('group1')

      allow(clock).to receive(:now).and_return(now + cache_time - 1)
      subject.find_group('group1')
    end

    it 'expires the cache after the cache time' do
      expect(delegate).to receive(:find_group).with('group1').twice.and_return(group)

      subject.find_group('group1')
      allow(clock).to receive(:now).and_return(now + cache_time)
      subject.find_group('group1')
    end
  end

  describe '#add_feature' do
    let(:feature_data) {{name: 'feat_name', group: 'group_name', description: '', active: true}}

    it 'adds the feature to the delegate' do
      expect(delegate).to receive(:add_feature).with(feature_data).and_return(feature)

      result = subject.add_feature(feature_data)
      expect(result).to eq(feature)
    end

    it 'invalidates the fetch feature cache' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').twice.and_return(feature)
      allow(delegate).to receive(:add_feature).with(feature_data)

      subject.fetch_feature('group1', 'feature1')

      subject.add_feature(feature_data)

      subject.fetch_feature('group1', 'feature1')
    end

    it 'invalidates the fetch group features cache' do
      expect(delegate).to receive(:fetch_group_features).with('group1').twice.and_return(features)
      allow(delegate).to receive(:add_feature).with(feature_data)

      subject.fetch_group_features('group1')

      subject.add_feature(feature_data)

      subject.fetch_group_features('group1')
    end
  end

  describe '#add_features' do
    let(:features_data) do
      [
          {name: 'feature_name', group: 'feature_group', description: '', active: true},
          {name: 'feature_name2', group: 'feature_group', description: '', active: true}
      ]
    end

    it 'adds the features to the delegate' do
      expect(delegate).to receive(:add_features).with(features_data).and_return(features)

      result = subject.add_features(features_data)

      expect(result).to eq(features)
    end

    it 'invalidates the fetch feature cache' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').twice.and_return(feature)
      allow(delegate).to receive(:add_features).with(features_data)

      subject.fetch_feature('group1', 'feature1')

      subject.add_features(features_data)

      subject.fetch_feature('group1', 'feature1')
    end

    it 'invalidates the fetch group features cache' do
      expect(delegate).to receive(:fetch_group_features).with('group1').twice.and_return(features)
      allow(delegate).to receive(:add_features).with(features_data)

      subject.fetch_group_features('group1')

      subject.add_features(features_data)

      subject.fetch_group_features('group1')
    end
  end

  describe '#remove_feature' do
    it 'removes the feature from the delegate' do
      expect(delegate).to receive(:remove_feature).with('group1', 'feature2').and_return(1)

      result = subject.remove_feature('group1', 'feature2')
      expect(result).to eq(1)
    end

    it 'invalidates the fetch feature cache' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').twice.and_return(feature)
      allow(delegate).to receive(:remove_feature).with('group1', 'feature2')

      subject.fetch_feature('group1', 'feature1')

      subject.remove_feature('group1', 'feature2')

      subject.fetch_feature('group1', 'feature1')
    end

    it 'invalidates the fetch group features cache' do
      expect(delegate).to receive(:fetch_group_features).with('group1').twice.and_return(features)
      allow(delegate).to receive(:remove_feature).with('group1', 'feature2')

      subject.fetch_group_features('group1')

      subject.remove_feature('group1', 'feature2')

      subject.fetch_group_features('group1')
    end
  end

  describe '#update_feature' do
    let(:updated_feature) {{description: 'updated', active: true}}

    it 'updates the feature on the delegate' do
      expect(delegate).to receive(:update_feature).with('group1', 'feature1', updated_feature).and_return(feature)

      result = subject.update_feature('group1', 'feature1', updated_feature)
      expect(result).to eq(feature)
    end

    it 'invalidates the fetch feature cache' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').twice.and_return(feature)
      allow(delegate).to receive(:update_feature).with('group1', 'feature1', updated_feature)

      subject.fetch_feature('group1', 'feature1')

      subject.update_feature('group1', 'feature1', updated_feature)

      subject.fetch_feature('group1', 'feature1')
    end

    it 'invalidates the fetch group features cache' do
      expect(delegate).to receive(:fetch_group_features).with('group1').twice.and_return(features)
      allow(delegate).to receive(:update_feature).with('group1', 'feature1', updated_feature)

      subject.fetch_group_features('group1')

      subject.update_feature('group1', 'feature1', updated_feature)

      subject.fetch_group_features('group1')
    end
  end

  describe '#fetch_feature' do
    let(:another_feature) {Bandiera::Feature.new(name: 'feature3')}

    it 'returns the feature from the delegate' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').and_return(feature)

      result = subject.fetch_feature('group1', 'feature1')

      expect(result).to be_an_instance_of(Bandiera::Feature)
      expect(result.name).to eq('feature1')
    end

    it 'caches subsequent calls' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').and_return(feature)

      subject.fetch_feature('group1', 'feature1')

      result = subject.fetch_feature('group1', 'feature1')

      expect(result).to be_an_instance_of(Bandiera::Feature)
      expect(result.name).to eq('feature1')
    end

    it 'does not share the cache expiry between keys' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').twice.and_return(feature)
      expect(delegate).to receive(:fetch_feature).with('group2', 'feature3').and_return(another_feature)

      subject.fetch_feature('group1', 'feature1')
      allow(clock).to receive(:now).and_return(now + (cache_time - 1))
      subject.fetch_feature('group2', 'feature3')

      allow(clock).to receive(:now).and_return(now + cache_time)
      subject.fetch_feature('group1', 'feature1')
      subject.fetch_feature('group2', 'feature3')
    end

    it 'does not cache errors' do
      call_count = 0
      allow(delegate).to receive(:fetch_feature) do
        call_count += 1
        call_count == 1 ? raise(Bandiera::FeatureService::FeatureNotFound.new) : feature
      end

      expect {subject.fetch_feature('group1', 'feature1')}.to raise_error(Bandiera::FeatureService::FeatureNotFound)

      result = subject.fetch_feature('group1', 'feature1')
      expect(result).to be_an_instance_of(Bandiera::Feature)
      expect(result.name).to eq('feature1')
      expect(call_count).to eq(2)
    end

    it 'serves from the cache up to the cached time' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').and_return(feature)

      subject.fetch_feature('group1', 'feature1')

      allow(clock).to receive(:now).and_return(now + cache_time - 1)
      subject.fetch_feature('group1', 'feature1')
    end

    it 'expires the cache after the cache time' do
      expect(delegate).to receive(:fetch_feature).with('group1', 'feature1').twice.and_return(feature)

      subject.fetch_feature('group1', 'feature1')
      allow(clock).to receive(:now).and_return(now + cache_time)
      subject.fetch_feature('group1', 'feature1')
    end
  end

  describe '#fetch_group_features' do
    let(:another_features) {[Bandiera::Feature.new(name: 'feature3'),
                             Bandiera::Feature.new(name: 'feature4')]}

    it 'returns the features from the delegate' do
      expect(delegate).to receive(:fetch_group_features).with('group1').and_return(features)

      result = subject.fetch_group_features('group1')

      expect(result.first).to be_an_instance_of(Bandiera::Feature)
      expect(result.first.name).to eq('feature1')
    end

    it 'caches subsequent calls' do
      expect(delegate).to receive(:fetch_group_features).with('group1').and_return(features)

      subject.fetch_group_features('group1')

      result = subject.fetch_group_features('group1')

      expect(result.first).to be_an_instance_of(Bandiera::Feature)
      expect(result.first.name).to eq('feature1')
    end

    it 'does not share the cache expiry between keys' do
      expect(delegate).to receive(:fetch_group_features).with('group1').twice.and_return(features)
      expect(delegate).to receive(:fetch_group_features).with('group2').and_return(another_features)

      subject.fetch_group_features('group1')
      allow(clock).to receive(:now).and_return(now + (cache_time - 1))
      subject.fetch_group_features('group2')

      allow(clock).to receive(:now).and_return(now + cache_time)
      subject.fetch_group_features('group1')
      subject.fetch_group_features('group2')
    end

    it 'does not cache errors' do
      call_count = 0
      allow(delegate).to receive(:fetch_group_features) do
        call_count += 1
        call_count == 1 ? raise(Bandiera::FeatureService::GroupNotFound.new) : features
      end

      expect {subject.fetch_group_features('group1')}.to raise_error(Bandiera::FeatureService::GroupNotFound)

      result = subject.fetch_group_features('group1')
      expect(result.first).to be_an_instance_of(Bandiera::Feature)
      expect(result.first.name).to eq('feature1')
      expect(call_count).to eq(2)
    end

    it 'serves from the cache up to the cached time' do
      expect(delegate).to receive(:fetch_group_features).with('group1').and_return(features)

      subject.fetch_group_features('group1')

      allow(clock).to receive(:now).and_return(now + cache_time - 1)
      subject.fetch_group_features('group1')
    end

    it 'expires the cache after the cache time' do
      expect(delegate).to receive(:fetch_group_features).with('group1').twice.and_return(features)

      subject.fetch_group_features('group1')
      allow(clock).to receive(:now).and_return(now + cache_time)
      subject.fetch_group_features('group1')
    end
  end

end
