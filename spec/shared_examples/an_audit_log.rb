# frozen_string_literal: true

shared_examples_for 'an audit log' do
  describe 'logging methods' do
    it 'responds to #record?' do
      should respond_to(:record).with(4).arguments
    end
  end
end
