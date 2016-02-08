require 'spec_helper'

RSpec.describe Hash do
  describe '#symbolize_keys' do
    it 'symbolizes keys recursivley' do
      original = {
        'woo' => 'wibble',
        'foo' => { 'bar' => 'bar', :wee => 'wee' }
      }

      target = {
        woo: 'wibble',
        foo: { bar: 'bar', wee: 'wee' }
      }

      expect(original.symbolize_keys).to eq(target)
    end
  end
end
