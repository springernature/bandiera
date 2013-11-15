require 'spec_helper'

describe Feature do

  it "belongs to a group" do
    group = Group.create(name: 'pubserv')
    feature = Feature.create(name: 'test', group: group)
    expect(feature.group).to eq group
  end
end
