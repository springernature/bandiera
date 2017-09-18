require 'spec_helper'

RSpec.describe Bandiera::FeatureService do
  subject { Bandiera::FeatureService.new }

  it_behaves_like 'a feature service'
end
