require 'spec_helper'

RSpec.describe Yoda::Typing::Inferencer::ArgumentsBinder do
  let(:registry) { Yoda::Store::Registry.new(Yoda::Store::Adapters::MemoryAdapter.new) }
  let(:generator) { Yoda::Typing::Types::Generator.new(registry) }

  let(:binder) { described_class.new(generator: generator) }

  describe '#bind' do
    subject { binder.bind(types: types, arguments: arguments) }

    context 'parameters are given' do
      let(:arguments) do
        Yoda::Model::Parameters::Multiple.new(
          parameters: [
            Yoda::Model::Parameters::Named.new(:a),
            Yoda::Model::Parameters::Named.new(:b),
            Yoda::Model::Parameters::Named.new(:c),
          ],
        )
      end
      let(:types) do
        [
          Yoda::Typing::Types::Function.new(
            parameters: [
              generator.string_type,
              generator.symbol_type,
              generator.integer_type,
            ],
            return_type: Yoda::Typing::Types::Any.new,
          ),
        ]
      end

      it do
        is_expected.to match({
          a: have_attributes(klass: have_attributes(path: 'String')),
          b: have_attributes(klass: have_attributes(path: 'Symbol')),
          c: have_attributes(klass: have_attributes(path: 'Integer')),
        })
      end
    end

    context 'parameters and rest parameter are given' do
      let(:arguments) do
        Yoda::Model::Parameters::Multiple.new(
          parameters: [
            Yoda::Model::Parameters::Named.new(:a),
            Yoda::Model::Parameters::Named.new(:b),
          ],
          rest_parameter: Yoda::Model::Parameters::Named.new(:c),
        )
      end
      let(:types) do
        [
          Yoda::Typing::Types::Function.new(
            parameters: [
              generator.string_type,
              generator.symbol_type,
              generator.integer_type,
            ],
            return_type: Yoda::Typing::Types::Any.new,
          ),
        ]
      end

      it do
        is_expected.to match({
          a: have_attributes(klass: have_attributes(path: 'String')),
          b: have_attributes(klass: have_attributes(path: 'Symbol')),
          c: have_attributes(klass: have_attributes(path: 'Array')),
        })
      end
    end
  end
end
