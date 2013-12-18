require "spec_helper"

describe Bandiera::Db do
  subject { Bandiera::Db.connection }

  describe "the features table" do
    it "should be present" do
      expect(subject.tables).to include(:groups)
      expect(subject.tables).to include(:features)
    end

    it "should be empty" do
      expect(subject[:groups]).to be_empty
      expect(subject[:features]).to be_empty
    end

    it "should allow us to enter data" do
      subject[:groups] << { name: "qwerty" }

      group = subject[:groups].first

      subject[:features] << { group_id: group[:id], name: "woo" }
      subject[:features] << { group_id: group[:id], name: "woo2" }
      expect(subject[:features].count).to eq(2)
    end
  end
end

