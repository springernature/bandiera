require 'spec_helper'

RSpec.describe Bandiera::Db do
  subject { Bandiera::Db.connect }

  describe 'the features table' do
    it 'should be present' do
      expect(subject.tables).to include(:groups)
      expect(subject.tables).to include(:features)
    end

    it 'should be empty' do
      expect(subject[:groups]).to be_empty
      expect(subject[:features]).to be_empty
    end

    it 'should allow us to enter data' do
      subject[:groups] << { name: 'qwerty' }

      group = subject[:groups].first

      subject[:features] << { group_id: group[:id], name: 'woo' }
      subject[:features] << { group_id: group[:id], name: 'woo2' }
      expect(subject[:features].count).to eq(2)
    end
  end

  describe '#ready?' do
    context 'when the database is up and ready' do
      it 'returns true' do
        expect(Bandiera::Db.ready?).to be true
      end
    end

    context 'when the database is not available' do
      let(:connection_double) { double(:connection) }

      before do
        allow(Bandiera::Db).to receive(:connect).and_return(connection_double)
        allow(connection_double).to receive(:execute).and_raise(Sequel::DatabaseDisconnectError, 'Boom')
      end

      it 'returns false' do
        expect(Bandiera::Db.ready?).to be false
      end
    end
  end
end
