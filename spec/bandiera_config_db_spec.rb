require "spec_helper"

describe BandieraConfig::DB do
  subject { BandieraConfig::DB }

  describe "the features table" do
    it "should be present" do
      expect(subject.tables).to include(:features)
    end

    it "should be empty" do
      expect(subject[:features]).to be_empty
    end

    it "should allow us to enter data" do
      subject[:features] << { group: "foo", name: "woo" }
      subject[:features] << { group: "foo", name: "woo2" }
      expect(subject[:features].count).to eq(2)
    end
  end
end

