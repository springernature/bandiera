require 'spec_helper'

RSpec.describe Bandiera::WebAuditContext do
  let(:request) { Rack::Request.new(Rack::MockRequest.env_for('/a/path', 'REMOTE_ADDR' => '1.2.3.4')) }
  subject { Bandiera::WebAuditContext.new(request) }

  it_behaves_like 'an audit context'

  describe '#user_id' do
    it 'returns the current remote IP address' do
      expect(subject.user_id).to eq('1.2.3.4')
    end
  end
end
