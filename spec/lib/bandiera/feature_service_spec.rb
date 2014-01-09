require "spec_helper"

describe Bandiera::FeatureService do
  let(:db) { Bandiera::Db.connection }
  subject { Bandiera::FeatureService.new }

  describe "#add_group" do
    it "adds a new group" do
      expect(db[:groups]).to be_empty
      subject.add_group("burgers")
      expect(db[:groups].select_map(:name)).to eq(["burgers"])
    end
  end

  describe "#add_feature" do
    it "calls #add_features" do
      feature_hash   = { name: "name", group: "group", description: "", enabled: true }
      feature_double = double("feature")

      subject
        .should_receive(:add_features)
        .with([feature_hash])
        .and_return([feature_double])

      result = subject.add_feature(feature_hash)
      expect(result).to eq(feature_double)
    end
  end

  describe "#add_features" do
    before do
      @features = [
        { name: "feature_name", group: "feature_group", description: "", enabled: true },
        { name: "feature_name2", group: "feature_group", description: "", enabled: true }
      ]
    end

    context "when a group exists" do
      before do
        db[:groups] << { name: "feature_group" }
      end

      it "creates features without creating a new group" do
        expect(db[:groups].select_map(:name)).to eq(["feature_group"])

        returned_features = subject.add_features(@features)

        expect(db[:groups].select_map(:name)).to eq(["feature_group"])
        expect(db[:features].select_map(:name)).to eq(["feature_name", "feature_name2"])

        expect(returned_features).to be_an_instance_of(Array)
        expect(returned_features.first).to be_an_instance_of(Bandiera::Feature)
        expect(returned_features.size).to eq(2)
      end

      context "when one or more of the features already exists" do
        it "updates the existing features" do
          pre_existing_feature = @features.first.dup
          pre_existing_feature.delete(:group)
          pre_existing_feature[:enabled]  = false
          pre_existing_feature[:group_id] = db[:groups].first[:id]

          db[:features] << pre_existing_feature

          feature = subject.get_feature("feature_group", pre_existing_feature[:name])
          expect(feature.enabled).to be_false

          subject.add_features(@features)

          feature = subject.get_feature("feature_group", pre_existing_feature[:name])
          expect(feature.enabled).to be_true
        end
      end
    end

    context "when a group doesn't exist" do
      it "creates both the group and the features" do
        expect(db[:groups]).to be_empty

        returned_features = subject.add_features(@features)

        expect(db[:groups].select_map(:name)).to eq(["feature_group"])
        expect(db[:features].select_map(:name)).to eq(["feature_name", "feature_name2"])
      end
    end
  end

  describe "#remove_feature" do
    context "when the group doesn't exist" do
      it "raises a RecordNotFound error" do
        expect {
          subject.remove_feature("burgers", "foo")
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end

    context "when the feature doesn't exist" do
      before do
        db[:groups] << { name: "group1" }
      end

      it "raises a RecordNotFound error" do
        expect {
          subject.remove_feature("group1", "foo")
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end

    context "when both the group and the feature exist" do
      before do
        subject.add_feature({ name: "feat", group: "group", description: "", enabled: false })
      end

      it "removes a feature record" do
        subject.remove_feature("group", "feat")
        expect(db[:groups].count).to eq(1) # we don't remove the group
        expect(db[:features]).to be_empty
      end
    end
  end

  describe "#update_feature" do
    context "when the group doesn't exist" do
      it "raises a RecordNotFound error" do
        expect {
          subject.update_feature("my_group", "my_feature", {})
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end

    context "when the feature doesn't exist" do
      before do
        db[:groups] << { name: "my_group" }
      end

      it "raises a RecordNotFound error" do
        expect {
          subject.update_feature("my_group", "my_feature", {})
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end

    context "when the group/feature does exist" do
      before do
        subject.add_feature({
          name: "feat",
          group: "group",
          description: "",
          enabled: false
        })
      end

      it "updates the feature" do
        feature = subject.update_feature("group", "feat", { name: "updated", enabled: true })

        expect(feature.name).to eq("updated")
        expect(feature.enabled?).to be_true

        expect {
          subject.get_feature("group", "feat")
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end
  end

  describe "#get_groups" do
    before do
      db[:groups] << { name: "group1" }
      db[:groups] << { name: "group2" }
    end

    it "gets a list of all groups" do
      expect(subject.get_groups).to eq(["group1", "group2"])
    end
  end

  describe "#get_group_features" do
    before do
      subject.add_features([
        { name: "feature1", group: "group_name" },
        { name: "feature2", group: "group_name" },
        { name: "wibble", group: "something_else" }
      ])
    end

    context "when the group exists" do
      it "gets all features for a group" do
        features = subject.get_group_features("group_name")

        expect(features).to be_an_instance_of(Array)
        expect(features.size).to eq(2)
        expect(features.first).to be_an_instance_of(Bandiera::Feature)

        names = features.map(&:name)
        expect(names).to eq(["feature1","feature2"])
      end
    end

    context "when the group doesn't exist" do
      it "raises a Bandiera::FeatureService::RecordNotFound error" do
        expect {
          subject.get_group_features("burgers")
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end
  end

  describe "#get_feature" do
    context "when both the group and the feature exists" do
      before do
        subject.add_feature(group: "group1", name: "feature1")
      end

      it "returns the feature" do
        feature = subject.get_feature("group1", "feature1")
        expect(feature).to be_an_instance_of(Bandiera::Feature)
        expect(feature.name).to eq "feature1"
      end
    end

    context "when the group doesn't exist" do
      it "raises a Bandiera::FeatureService::RecordNotFound error" do
        expect {
          subject.get_feature("cheeses", "stilton")
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end

    context "when the feature doesn't exist" do
      before do
        db[:groups] << { name: "cheeses" }
      end

      it "raises a Bandiera::FeatureService::RecordNotFound error" do
        expect {
          subject.get_feature("cheeses", "stilton")
        }.to raise_error(Bandiera::FeatureService::RecordNotFound)
      end
    end
  end
end
