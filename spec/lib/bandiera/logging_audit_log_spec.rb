require 'spec_helper'

RSpec.describe Bandiera::LoggingAuditLog do
  let(:db) { Bandiera::Db.connect }
  let(:audit_context) { Bandiera::AnonymousAuditContext.new }
  subject { Bandiera::LoggingAuditLog.new(db) }

  it_behaves_like 'an audit log'

  describe '#record' do
    it 'records the audit message to the audit log' do
      expect(db[:audit_records]).to be_empty

      subject.record(audit_context, :add, :foodstuff, name: 'burger')

      audit_record = db[:audit_records].first
      expect(audit_record).to_not be_nil
      expect(audit_record[:user]).to eq('<anonymous>')
      expect(audit_record[:action]).to eq('add')
      expect(audit_record[:object]).to eq('foodstuff')
      expect(JSON.parse(audit_record[:params]).symbolize_keys).to eq({ name: 'burger' })
    end

    it 'sets the timestamp to the current time' do
      expect(db[:audit_records]).to be_empty
      expected_time = Time.local(2017, 1, 1, 12, 0, 0)

      Timecop.freeze(expected_time) do
        subject.record(audit_context, :add, :foodstuff, name: 'burger')
      end

      audit_record = db[:audit_records].first
      expect(audit_record).to_not be_nil
      expect(audit_record[:timestamp]).to eq(expected_time)
    end

    it 'handles no parameters' do
      expect(db[:audit_records]).to be_empty

      subject.record(audit_context, :add, :foodstuff)

      audit_record = db[:audit_records].first
      expect(audit_record).to_not be_nil
      expect(audit_record[:params]).to be_nil
    end

    it 'handles multiple parameters' do
      expect(db[:audit_records]).to be_empty

      subject.record(audit_context, :add, :foodstuff, name: 'burger', type: 'rare')

      audit_record = db[:audit_records].first
      expect(audit_record).to_not be_nil
      expect(JSON.parse(audit_record[:params]).symbolize_keys).to eq({ name: 'burger', type: 'rare' })
    end

    it 'does not propagate exceptions' do
      audit_record = instance_double('Bandiera::AuditRecord')
      expect(Bandiera::AuditRecord).to receive(:new).and_return(audit_record)
      expect(audit_record).to receive(:save).and_throw RuntimeError.new('This should not propagate')

      subject.record(audit_context, :add, :foodstuff, name: 'burger')
    end
  end
end
