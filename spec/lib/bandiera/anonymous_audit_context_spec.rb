require 'spec_helper'

RSpec.describe Bandiera::AnonymousAuditContext do
  subject { Bandiera::AnonymousAuditContext.new }

  it_behaves_like 'an audit context'

  describe '#user_id' do
    it 'returns an anonymous identifier' do
      expect(subject.user_id).to eq('<anonymous>')
    end
  end
end
