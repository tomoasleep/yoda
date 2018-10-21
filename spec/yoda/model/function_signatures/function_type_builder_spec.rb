require 'spec_helper'

RSpec.describe Yoda::Model::FunctionSignatures::TypeBuilder do
  include TypeHelper

  let(:builder) { described_class.new(parameter_list, tag_list) }
  let(:parameter_list) { Yoda::Model::FunctionSignatures::ParameterList.new(parameters) }
  let(:tag_list) { [] }
  let(:parameters) { [] }

  describe '#type' do
    subject { builder.type }

    context 'with no parameters and no tags' do
      it 'returns empty parameter function type' do
        expect(subject).to eq(
          Yoda::Model::TypeExpressions::FunctionType.new(
            return_type: unknown_type,
          )
        )
      end
    end

    context 'with a required parameter and no tags' do
      let(:parameters) { [['x', nil]] }

      it 'returns empty parameter function type' do
        expect(subject).to eq(
          Yoda::Model::TypeExpressions::FunctionType.new(
            required_parameters: [unknown_type],
            return_type: unknown_type,
          )
        )
      end
    end

    context 'with a required parameter and no tags' do
      let(:parameters) { [['x', nil], ['y', 'nil']] }

      it 'returns empty parameter function type' do
        expect(subject).to eq(
          Yoda::Model::TypeExpressions::FunctionType.new(
            required_parameters: [unknown_type],
            optional_parameters: [unknown_type],
            return_type: unknown_type,
          )
        )
      end
    end

    context 'with a required parameter and no tags' do
      let(:parameters) { [['x', nil], ['y', 'nil']] }
      let(:tag_list) do
        [
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'x', yard_types: ['Integer']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'y', yard_types: ['String']),
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Array']),
        ]
      end

      it 'returns empty parameter function type' do
        expect(subject).to eq(
          Yoda::Model::TypeExpressions::FunctionType.new(
            required_parameters: [instance_type('Integer').change_root(['Object'])],
            optional_parameters: [instance_type('String').change_root(['Object'])],
            return_type: instance_type('Array').change_root(['Object']),
          )
        )
      end
    end

  end
end
