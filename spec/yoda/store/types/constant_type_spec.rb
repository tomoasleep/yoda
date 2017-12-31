require 'spec_helper'

RSpec.describe Yoda::Store::Types::ConstantType do
  include TypeHelper

  describe 'equality' do
    subject { described_class.new(value) }

    context 'an integer string value is given' do
      let(:value) { '1' }
      it { is_expected.to eq constant_type('1') }
    end

    context 'a string value begin with upper case character is given' do
      let(:value) { 'Hoge' }
      it { is_expected.to eq constant_type('Hoge') }
    end

    context 'a lower case string value is given' do
      let(:value) { 'hoge' }
      it { is_expected.to eq constant_type('hoge') }
    end
  end
end
