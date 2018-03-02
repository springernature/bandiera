require 'spec_helper'

RSpec.describe Bandiera::LoggingAuditLog do
  let(:logger) { instance_double('Logger') }
  let(:audit_context) { Bandiera::AnonymousAuditContext.new }
  subject { Bandiera::LoggingAuditLog.new(logger) }

  it_behaves_like 'an audit log'

  describe '#record' do
    it 'records the audit message to the logger' do
      expect(logger).to receive(:log).with('AUDIT [<anonymous>] add foodstuff (name: burger)')

      subject.record(audit_context, :add, :foodstuff, name: 'burger')
    end

    it 'handles no parameters' do
      expect(logger).to receive(:log).with('AUDIT [<anonymous>] eat cake')

      subject.record(audit_context, :eat, :cake)
    end

    it 'handles multiple parameters' do
      expect(logger).to receive(:log).with('AUDIT [<anonymous>] add foodstuff (name: burger, type: rare)')

      subject.record(audit_context, :add, :foodstuff, name: 'burger', type: 'rare')
    end

    it 'does not propagate exceptions' do
      expect(logger).to receive(:log).and_throw RuntimeError.new('This should not propagate')

      subject.record(audit_context, :add, :foodstuff, name: 'burger')
    end
  end
end
