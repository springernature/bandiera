require 'spec_helper'

RSpec.describe Bandiera::FeatureService do
  let(:audit_context) { Bandiera::AnonymousAuditContext.new }
  let(:audit_log) { instance_double('Bandiera::AuditLog') }
  subject { Bandiera::FeatureService.new(audit_log) }

  before do
    allow(audit_log).to receive(:record)
  end

  it_behaves_like 'a feature service'

  describe '#add_group' do
    it 'records to the audit log' do
      expect(audit_log).to receive(:record).with(audit_context, :add, :group, name: 'cheese')

      subject.add_group(audit_context, 'cheese')
    end
  end

  describe '#add_feature' do
    it 'records to the audit log' do
      expect(audit_log).to receive(:record)
        .with(audit_context, :add, :feature, name: 'feat', group: 'group', active: false)

      subject.add_feature(audit_context, name: 'feat', group: 'group', active: false)
    end
  end

  describe '#add_features' do
    it 'records to the audit log' do
      expect(audit_log).to receive(:record)
        .with(audit_context, :add, :feature, name: 'feature1', group: 'group_name', active: nil)
        .with(audit_context, :add, :feature, name: 'feature2', group: 'group_name', active: nil)
        .with(audit_context, :add, :feature, name: 'wibble', group: 'something_else', active: nil)

      subject.add_features(audit_context, [
          { name: 'feature1', group: 'group_name' },
          { name: 'feature2', group: 'group_name' },
          { name: 'wibble', group: 'something_else' }
      ])
    end
  end

  describe '#remove_feature' do
    before do
      subject.add_feature(audit_context, { name: 'feat', group: 'group', description: '', active: false })
    end

    it 'records to the audit log' do
      expect(audit_log).to receive(:record)
        .with(audit_context, :remove, :feature, name: 'feat', group: 'group')

      subject.remove_feature(audit_context, 'group', 'feat')
    end
  end

  describe '#update_feature' do
    before do
      subject.add_feature(audit_context, { name: 'feat', group: 'group', description: '', active: false })
    end

    it 'records to the audit log' do
      expect(audit_log).to receive(:record)
        .with(audit_context, :update, :feature, name: 'feat', group: 'group',
          fields: { description: 'updated', active: true })

      subject.update_feature(audit_context, 'group', 'feat', description: 'updated', active: true)
    end
  end
end
