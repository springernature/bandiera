require 'spec_helper'

RSpec.describe Bandiera::Feature do
  let(:name)        { 'show-stuff' }
  let(:group)       { Bandiera::Group.create(name: 'group_name') }
  let(:description) { 'feature description' }
  let(:active)      { true }
  let(:user_groups) { nil }
  let(:percentage)  { nil }

  subject do
    Bandiera::Feature.create do |feat|
      feat.name        = name
      feat.group       = group
      feat.description = description
      feat.active      = active
      feat.user_groups = user_groups if user_groups
      feat.percentage  = percentage if percentage
    end
  end

  describe 'a plain on/off feature flag' do
    it 'responds to #enabled?' do
      expect(subject.respond_to?(:enabled?)).to eq true
    end

    context 'when @active is true' do
      describe '#enabled?' do
        it 'returns true' do
          expect(subject.enabled?).to eq true
        end
      end
    end

    context 'when @active is false' do
      let(:active) { false }

      describe '#enabled?' do
        it 'returns false' do
          expect(subject.enabled?).to eq false
        end
      end
    end
  end

  describe 'a feature for specific user groups' do
    context 'configured as a list of groups' do
      let(:user_group)  { 'admin' }
      let(:user_groups) { { list: %w(admin editor) } }

      context 'when @active is true' do
        describe '#enabled?' do
          context 'returns true' do
            it 'if the user_group is in the list' do
              expect(subject.enabled?(user_group: user_group)).to eq true
            end

            it 'if the user_group is in the list regardless of case' do
              expect(subject.enabled?(user_group: user_group.upcase)).to eq true
            end
          end

          context 'returns false' do
            let(:user_group) { 'guest' }

            it 'if the user_group is not in the list' do
              expect(subject.enabled?(user_group: user_group)).to eq false
            end

            it 'if no user_group argument was passed' do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end

      context 'when @active is false' do
        let(:active) { false }

        describe '#enabled?' do
          it 'always returns false' do
            expect(subject.enabled?(user_group: user_group)).to eq false
          end
        end
      end

      context 'when users have blank lines in their list of groups' do
        let(:user_groups) { { list: ['admin', '', 'editor', ''] } }

        describe 'enabled?' do
          it 'ignores these values when considering the user_group' do
            expect(subject.enabled?(user_group: 'admin')).to eq true
            expect(subject.enabled?(user_group: '')).to eq false
          end
        end
      end
    end

    context 'configured as a regex' do
      let(:user_group)  { 'admin' }
      let(:user_groups) { { regex: '.*admin.*' } }

      context 'when @active is true' do
        describe '#enabled?' do
          context 'returns true' do
            it 'if the user_group matches the regex' do
              expect(subject.enabled?(user_group: user_group)).to eq true
            end
          end

          context 'returns false' do
            let(:user_group) { 'guest' }

            it 'if the user_group does not match the regex' do
              expect(subject.enabled?(user_group: user_group)).to eq false
            end

            it 'if no user_group argument was passed' do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end

      context 'when @active is false' do
        let(:active) { false }

        describe '#enabled?' do
          it 'always returns false' do
            expect(subject.enabled?(user_group: user_group)).to eq false
          end
        end
      end

      context 'with a wrong regex' do
        let(:active)      { true }
        let(:user_groups) { { regex: '*admin' } }

        it 'returns false without raisning an error' do
          expect(subject.enabled?(user_group: user_group)).to eq false
        end
      end
    end

    context 'configured as a combination of exact matches and a regex' do
      let(:user_groups) { { list: %w(editor), regex: '.*admin' } }

      context 'when @active is true' do
        describe '#enabled?' do
          context 'returns true' do
            it 'if the user_group is in the exact match list but does not match the regex' do
              expect(subject.enabled?(user_group: 'editor')).to eq true
            end

            it 'if the user_group matches the regex but is not in the exact match list' do
              expect(subject.enabled?(user_group: 'super_admin')).to eq true
            end
          end

          context 'returns false' do
            it 'if the user_group is not in the exact match list and does not match the regex' do
              expect(subject.enabled?(user_group: 'guest')).to eq false
            end

            it 'if no user_group argument was passed' do
              expect(subject.enabled?).to eq false
            end
          end
        end
      end

      context 'when @active is false' do
        let(:active) { false }

        describe '#enabled?' do
          it 'always returns false' do
            expect(subject.enabled?(user_group: 'editor')).to eq false
          end
        end
      end
    end
  end

  describe 'a feature for a percentage of users' do
    context 'when @active is true' do
      context 'with 5%' do
        let(:percentage) { 5 }

        describe '#enabled?' do
          it 'returns true for ~5% of users' do
            expect(calculate_active_count(subject, percentage)).to be < 15
          end
        end
      end

      context 'with 95%' do
        let(:percentage) { 95 }

        describe '#enabled?' do
          it 'returns true for ~95% of users' do
            expect(calculate_active_count(subject, percentage)).to be > 85
            expect(calculate_active_count(subject, percentage)).to be < 100
          end
        end
      end

      context 'when no user_id is passed' do
        let(:percentage) { 95 }

        describe '#enabled?' do
          it 'returns false' do
            expect(subject.enabled?).to eq false
          end
        end
      end
    end

    context 'when @active is false' do
      let(:percentage) { 95 }
      let(:active) { false }

      describe '#enabled?' do
        it 'returns false' do
          expect(calculate_active_count(subject, percentage)).to be == 0
        end
      end
    end
  end

  describe 'a feature configured for both user groups and a percentage of users' do
    context 'when @active is true' do
      context 'and the user matches on the user_group configuration' do
        let(:user_groups) { { list: %w(admin editor) } }
        let(:percentage)  { 5 }

        describe '#enabled?' do
          it 'returns true' do
            expect(subject.enabled?(user_group: 'admin', user_id: 12_345)).to eq true
          end
        end
      end

      context 'and the user does not match the user_groups, but does fall into the percentage' do
        let(:user_groups) { { list: %w(admin editor) } }
        let(:percentage)  { 100 }

        describe '#enabled?' do
          it 'returns true' do
            expect(subject.enabled?(user_group: 'qwerty', user_id: 12_345)).to eq true
          end
        end
      end

      context 'and the user matches neither the user_groups or falls into the percentage' do
        let(:user_groups) { { list: %w(admin editor) } }
        let(:percentage)  { 5 }

        before do
          allow(subject).to receive(:percentage_enabled_for_user?).and_return(false)
        end

        describe '#enabled?' do
          it 'returns false' do
            expect(subject.enabled?(user_group: 'qwerty', user_id: 12_345)).to eq false
          end
        end
      end

      context 'when the user_group and/or user_id params are not passed' do
        let(:user_groups) { { list: %w(admin editor) } }
        let(:percentage)  { 100 }

        describe '#enabled?' do
          it 'returns false' do
            expect(subject.enabled?).to eq false
          end
        end
      end
    end

    context 'when @active is false' do
      let(:user_groups) { { list: %w(admin editor) } }
      let(:percentage)  { 100 }
      let(:active)      { false }

      describe '#enabled?' do
        it 'returns false' do
          expect(subject.enabled?(user_group: 'admin', user_id: 12_345)).to eq false
        end
      end
    end
  end

  describe '#report_enabled_warnings' do
    context 'a disabled feature' do
      let(:active) { false }

      it 'returns an empty array' do
        expect(subject.report_enabled_warnings).to eq([])
      end
    end

    context 'with a on/off feature' do
      it 'returns an empty array' do
        expect(subject.report_enabled_warnings).to eq([])
      end
    end

    context 'with a user group feature' do
      let(:user_groups) { { list: %w(admin editor) } }

      context 'when user_group HAS been supplied' do
        it 'returns an empty array' do
          expect(subject.report_enabled_warnings(user_group: 'bob')).to eq([])
        end
      end

      context 'when user_group HAS NOT been supplied' do
        it 'returns a populated warning array' do
          expect(subject.report_enabled_warnings).to eq([:user_group])
        end
      end
    end

    context 'with a percentage feature' do
      let(:percentage)  { 20 }

      context 'when user_id HAS been supplied' do
        it 'returns an empty array' do
          expect(subject.report_enabled_warnings(user_id: '12_345')).to eq([])
        end
      end

      context 'when user_id HAS NOT been supplied' do
        it 'returns a populated warning array' do
          expect(subject.report_enabled_warnings).to eq([:user_id])
        end
      end
    end

    context 'with a user group and percentage feature' do
      let(:user_groups) { { list: %w(admin editor) } }
      let(:percentage)  { 20 }

      context 'when user_group and user_id HAS been supplied' do
        it 'returns an empty array' do
          expect(subject.report_enabled_warnings(user_group: 'bob', user_id: '12_345')).to eq([])
        end
      end

      context 'when user_group and user_id HAS NOT been supplied' do
        it 'returns a populated warning array' do
          expect(subject.report_enabled_warnings).to eq([:user_group, :user_id])
        end
      end

      context 'when user_group HAS, but user_id HAS NOT been supplied' do
        it 'returns a populated warning array' do
          expect(subject.report_enabled_warnings(user_group: 'bob')).to eq([:user_id])
        end
      end

      context 'when user_group HAS NOT, but user_id HAS been supplied' do
        it 'returns a populated warning array' do
          expect(subject.report_enabled_warnings(user_id: '12345')).to eq([:user_group])
        end
      end
    end
  end

  describe '#user_groups_configured?' do
    let(:user_groups) { Hash.new }

    context 'if a user_group list have been configured' do
      let(:user_groups) { { list: %w(boo bar) } }

      it 'returns true' do
        expect(subject.user_groups_configured?).to eq true
      end
    end

    context 'if a user_group regex have been configured' do
      let(:user_groups) { { regex: '.*' } }

      it 'returns true' do
        expect(subject.user_groups_configured?).to eq true
      end
    end

    context 'if no user_group settings have been configured' do
      it 'returns false' do
        expect(subject.user_groups_configured?).to eq false
      end
    end
  end

  private

  def calculate_active_count(feature, _percentage)
    (0...100)
      .map   { |id| feature.enabled?(user_id: id) }
      .count { |val| val == true }
  end
end
