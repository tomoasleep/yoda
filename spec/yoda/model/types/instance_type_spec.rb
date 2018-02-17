require 'spec_helper'

RSpec.describe Yoda::Model::Types::InstanceType do
  include TypeHelper

  describe 'equality' do
    subject { described_class.new(value) }

    context 'a string value begin with upper case character is given' do
      let(:value) { 'Hoge' }
      it { is_expected.to eq instance_type('Hoge') }
    end
  end
end
