require 'spec_helper'

RSpec.describe Yoda::Model::Types::UnionType do
  include TypeHelper

  describe 'equality' do
    subject { described_class.new(types) }

    context 'multiple constant type is given' do
      let(:types) { [value_type('1'), value_type('2')] }
      it { is_expected.to eq union_type(value_type('1'), value_type('2')) }
      it { is_expected.to eq union_type(value_type('2'), value_type('1')) }
    end
  end
end
