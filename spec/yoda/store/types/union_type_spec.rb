require 'spec_helper'

RSpec.describe Yoda::Store::Types::UnionType do
  include TypeHelper

  describe 'equality' do
    subject { described_class.new(types) }

    context 'multiple constant type is given' do
      let(:types) { [constant_type('1'), constant_type('2')] }
      it { is_expected.to eq union_type(constant_type('1'), constant_type('2')) }
      it { is_expected.to eq union_type(constant_type('2'), constant_type('1')) }
    end
  end
end
