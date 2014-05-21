require 'spec_helper'

describe Bandiera::Feature do
  let(:name)        { 'show-stuff' }
  let(:group)       { Bandiera::Group.create(name: 'group_name') }
  let(:description) { 'feature description' }
  let(:active)      { true }
  let(:user_groups) { nil }

  subject do
    Bandiera::Feature.create do |feat|
      feat.name        = name
      feat.group       = group
      feat.description = description
      feat.active      = active
      feat.user_groups = user_groups if user_groups
    end
  end

  describe 'a plain on/off feature flag' do
    it 'responds to #enabled?' do
      expect(subject.respond_to?(:enabled?)).to be_true
    end

    context 'when @active is true' do
      describe '#enabled?' do
        it 'returns true' do
          expect(subject.enabled?).to be_true
        end
      end
    end

    context 'when @active is false' do
      let(:active) { false }

      describe '#enabled?' do
        it 'returns false' do
          expect(subject.enabled?).to be_false
        end
      end
    end
  end

  describe 'a feature for specific user groups' do
    context 'configured as a list of groups' do
      let(:user_group) { 'admin' }
      let(:user_groups) do
        { list: %w(admin editor) }
      end

      context 'when @active is true' do
        describe '#enabled?' do
          context 'returns true' do
            it 'if the user_group is in the list' do
              expect(subject.enabled?(user_group: user_group)).to be_true
            end
          end

          context 'returns false' do
            let(:user_group) { 'guest' }

            it 'if the user_group is not in the list' do
              expect(subject.enabled?(user_group: user_group)).to be_false
            end

            it 'if no user_group is passed through' do
              expect(subject.enabled?).to be_false
            end
          end
        end
      end

      context 'when @active is false' do
        let(:active) { false }

        describe '#enabled?' do
          it 'always returns false' do
            expect(subject.enabled?(user_group: user_group)).to be_false
          end
        end
      end

      context 'when users have blank lines in their list of groups' do
        let(:user_groups) do
          { list: ['admin', '', 'editor', ''] }
        end

        describe 'enabled?' do
          it 'ignores these values when considering the user_group' do
            expect(subject.enabled?(user_group: 'admin')).to be_true
            expect(subject.enabled?(user_group: '')).to be_false
          end
        end
      end
    end

    context 'configured as a regex' do
      let(:user_group) { 'admin' }
      let(:user_groups) do
        { regex: '.*admin.*' }
      end

      context 'when @active is true' do
        describe '#enabled?' do
          context 'returns true' do
            it 'if the user_group matches the regex' do
              expect(subject.enabled?(user_group: user_group)).to be_true
            end
          end

          context 'returns false' do
            let(:user_group) { 'guest' }

            it 'if the user_group does not match the regex' do
              expect(subject.enabled?(user_group: user_group)).to be_false
            end
          end
        end
      end

      context 'when @active is false' do
        let(:active) { false }

        describe '#enabled?' do
          it 'always returns false' do
            expect(subject.enabled?(user_group: user_group)).to be_false
          end
        end
      end
    end

    context 'configured as a combination of exact matches and a regex' do
      let(:user_groups) do
        { list: %w(editor), regex: '.*admin' }
      end

      context 'when @active is true' do
        describe '#enabled?' do
          context 'returns true' do
            it 'if the user_group is in the exact match list but does not match the regex' do
              expect(subject.enabled?(user_group: 'editor')).to be_true
            end

            it 'if the user_group matches the regex but is not in the exact match list' do
              expect(subject.enabled?(user_group: 'super_admin')).to be_true
            end
          end

          context 'returns false' do
            it 'if the user_group is not in the exact match list and does not match the regex' do
              expect(subject.enabled?(user_group: 'guest')).to be_false
            end
          end
        end
      end

      context 'when @active is false' do
        let(:active) { false }

        describe '#enabled?' do
          it 'always returns false' do
            expect(subject.enabled?(user_group: 'editor')).to be_false
          end
        end
      end
    end
  end

  describe '#user_groups_configured?' do
    let(:user_groups) { Hash.new }

    context 'if a user_group list have been configured' do
      let(:user_groups) { { list: %w(boo bar) } }

      it 'returns true' do
        expect(subject.user_groups_configured?).to be_true
      end
    end

    context 'if a user_group regex have been configured' do
      let(:user_groups) { { regex: '.*' } }

      it 'returns true' do
        expect(subject.user_groups_configured?).to be_true
      end
    end

    context 'if no user_group settings have been configured' do
      it 'returns false' do
        expect(subject.user_groups_configured?).to be_false
      end
    end
  end
end
