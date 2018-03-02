# frozen_string_literal: true

shared_examples_for 'an audit context' do
  describe 'auditing information' do
    it 'responds to #user_id?' do
      should respond_to(:user_id).with(0).arguments
    end
  end
end
