require 'spec_helper'

RSpec.describe Yoda::Store::Types do
  include TypeHelper

  describe '.parse' do
    subject { described_class.parse(type_string) }

    context 'an integer is given' do
      let(:type_string) { '1' }
      it { is_expected.to eq constant_type('1') }
    end

    context 'a name begin with upper case character is given' do
      let(:type_string) { 'Hoge' }
      it { is_expected.to eq constant_type('Hoge') }
    end

    context 'a lower case string is given' do
      let(:type_string) { 'hoge' }
      it { is_expected.to eq constant_type('hoge') }
    end

    context 'multiple names are given' do
      let(:type_string) { 'hoge, Hoge'}
      it { is_expected.to eq union_type(constant_type('hoge'), constant_type('Hoge'))}
    end

    context 'a name with a type argument is given' do
      let(:type_string) { 'Array<Integer>'}
      it { is_expected.to eq generic_type('Array', constant_type('Integer')) }
    end

    context 'a name with multiple type arguments is given' do
      let(:type_string) { 'Array<Integer, nil>'}
      it { is_expected.to eq generic_type('Array', union_type(constant_type('Integer'), constant_type('nil'))) }
    end

    context 'shorthand array literal with a value is given' do
      let(:type_string) { '<Integer>'}
      it { is_expected.to eq generic_type('::Array', union_type(constant_type('Integer'))) }
    end

    context 'shorthand array literal with multiple values is given' do
      let(:type_string) { '<Integer, nil>'}
      it { is_expected.to eq generic_type('::Array', union_type(constant_type('Integer'), constant_type('nil'))) }
    end

    context 'hash type with a key type and a value type is given' do
      let(:type_string) { 'Hash{Integer => String}'}
      it { is_expected.to eq key_value_type('Hash', constant_type('Integer'), constant_type('String')) }
    end

    context 'hash type with mulitple key types and multiple value types is given' do
      let(:type_string) { 'Hash{Integer, nil => String, nil}'}
      it { is_expected.to eq key_value_type('Hash', union_type(constant_type('Integer'), constant_type('nil')), union_type(constant_type('String'), constant_type('nil'))) }
    end

    context 'shorthand hash literal with a key type and a value type is given' do
      let(:type_string) { '{Integer => String}'}
      it { is_expected.to eq key_value_type('::Hash', constant_type('Integer'), constant_type('String')) }
    end

    context 'shorthand hash literal  with mulitple key types and multiple value types is given' do
      let(:type_string) { '{Integer, nil => String, nil}'}
      it { is_expected.to eq key_value_type('::Hash', union_type(constant_type('Integer'), constant_type('nil')), union_type(constant_type('String'), constant_type('nil'))) }
    end

    context 'a sequence with a type is given' do
      let(:type_string) { 'Array(Integer)'}
      it { is_expected.to eq sequence_type('Array', constant_type('Integer')) }
    end

    context 'a name with multiple type arguments is given' do
      let(:type_string) { 'Array(Integer, String)'}
      it { is_expected.to eq sequence_type('Array', constant_type('Integer'), constant_type('String')) }
      it { is_expected.not_to eq sequence_type('Array', constant_type('String'), constant_type('Integer')) }
    end

    context 'shorthand sequence literal with a type is given' do
      let(:type_string) { '(Integer)'}
      it { is_expected.to eq sequence_type('::Array', constant_type('Integer')) }
    end

    context 'shorthand sequence literal with multiple types is given' do
      let(:type_string) { '(Integer, String)'}
      it { is_expected.to eq sequence_type('::Array', constant_type('Integer'), constant_type('String')) }
      it { is_expected.not_to eq sequence_type('::Array', constant_type('String'), constant_type('Integer')) }
    end
  end
end
