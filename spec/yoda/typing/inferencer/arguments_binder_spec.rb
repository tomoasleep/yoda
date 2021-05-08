require 'spec_helper'

RSpec.describe Yoda::Typing::Inferencer::ArgumentsBinder do
  let(:environment) { Yoda::Model::Environment.build }
  let(:generator) { Yoda::Typing::Types::Generator.new(environment: environment) }
  let(:binder) { described_class.new(generator: generator) }

  before do
    environment.registry.add_file_patch(Yoda::Store::Objects::Library.core.create_patch)
  end

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
          generator.rbs_method_type(
            required_parameters: [
              generator.string_type,
              generator.symbol_type,
              generator.integer_type,
            ],
            return_type: generator.any_type,
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
          generator.rbs_method_type(
            required_parameters: [
              generator.string_type,
              generator.symbol_type,
              generator.integer_type,
            ],
            return_type: generator.any_type,
          )
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
