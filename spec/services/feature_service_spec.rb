require_relative '../../lib/services/feature_service'
require 'redis'

describe FeatureService do
  let(:ns)              { 'bandiera-test' }
  let(:redis)           { Redis.new }
  let(:feature_service) {
    FeatureService.new(redis: redis, ns: ns)
  }

  before(:each) do
    keys = redis.keys("#{ns}*")
    redis.pipelined do
      keys.each do |k|
        redis.del(k)
      end
    end
  end

  describe "#add_group" do
    context "when no groups" do
      it "#groups should be an empty array" do
        feature_service.groups.should eq []
      end
    end

    context "when some groups are added" do
      before do
        feature_service.add_group('Group 1')
        feature_service.add_group('group 1')
        feature_service.add_group('GrouP 2')
      end
      it "#groups should return unique list of transliterate group names" do
        feature_service.groups.to_set.should eq ["group-1", "group-2"].to_set
      end
    end
  end

  describe "#add_feature" do
    before do
      feature_service.add_feature('test group', 'my feature',true, 'my test description')
    end

    it "Creates the associated group if it doesn't exist" do
      feature_service.groups.should eq ['test-group']
    end

    it "keeps track of the feature flags associated to each group" do
      feature_service.group_features('test-group').map { |f| f['flag'] }.should eq ['my-feature']
    end

    it "Saves the feature data" do
      expected = {
        'flag'        => 'my-feature',
        'description' => 'my test description',
        'enabled'     => true
      }
      feature_service.feature('Test Group', 'My Feature').should eq expected
      feature_service.feature('test-group', 'my-feature').should eq expected
    end
  end

  describe "#group_features" do
    before do
      [['group A', 'flag 1'],
       ['group A', 'flag 2'],
       ['group B', 'flag 1']].each do |(group, feature)|
         feature_service.add_feature(group, feature, true)
       end
    end

    it "returns the feature flags associated to a given group" do
      features = feature_service.group_features('group a')
      features.size.should eq 2
      features.first.should eq({'flag' => 'flag-1', 'enabled' => true, 'description' => nil})
      features.last.should  eq({'flag' => 'flag-2', 'enabled' => true, 'description' => nil})
    end
  end
end
