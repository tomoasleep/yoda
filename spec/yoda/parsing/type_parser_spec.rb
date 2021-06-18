require 'spec_helper'

RSpec.describe Yoda::Parsing::TypeParser do
  include TypeHelper

  def parameter(type)
    Yoda::Model::TypeExpressions::FunctionType::Parameter.new(type: type)
  end

  describe '.parse' do
    subject { described_class.new.parse(type_string) }

    context 'a name begin with upper case character is given' do
      let(:type_string) { 'nil' }
      it { is_expected.to eq value_type('nil') }
    end

    context 'a name begin with upper case character is given' do
      let(:type_string) { 'Hoge' }
      it { is_expected.to eq instance_type('Hoge') }
    end

    context 'a name begin with upper case character is given' do
      let(:type_string) { 'Hoge.class' }
      it { is_expected.to eq module_type('Hoge') }
    end

    context 'a name begin with upper case character is given' do
      let(:type_string) { 'Hoge.module' }
      it { is_expected.to eq module_type('Hoge') }
    end

    context 'multiple names separeted by bar are given' do
      let(:type_string) { 'Hoge | Fuga'}
      it { is_expected.to eq union_type(instance_type('Hoge'), instance_type('Fuga'))}
    end

    context 'a name with a type argument is given' do
      let(:type_string) { 'Array<Integer>'}
      it { is_expected.to eq generic_type(instance_type('Array'), instance_type('Integer')) }
    end

    context 'a name with multiple type arguments is given' do
      let(:type_string) { 'Array<Integer, nil>'}
      it { is_expected.to eq generic_type(instance_type('Array'), instance_type('Integer'), value_type('nil')) }
    end

    context 'function type with a param is given' do
      let(:type_string) { '(Integer) -> String'}
      it do
        is_expected.to eq Yoda::Model::TypeExpressions::FunctionType.new(
          required_parameters: [instance_type('Integer')].map(&method(:parameter)),
          return_type: instance_type('String'),
        )
      end
    end

    context 'function type with params is given' do
      let(:type_string) { '(Integer, Float) -> String'}
      it do
        is_expected.to eq Yoda::Model::TypeExpressions::FunctionType.new(
          required_parameters: [instance_type('Integer'), instance_type('Float')].map(&method(:parameter)),
          return_type: instance_type('String'),
        )
      end
    end

    context 'function type with params including generic types is given' do
      let(:type_string) { '(Integer, Array<Float>) -> String'}
      it do
        is_expected.to eq Yoda::Model::TypeExpressions::FunctionType.new(
          required_parameters: [instance_type('Integer'), generic_type(instance_type('Array'), instance_type('Float'))].map(&method(:parameter)),
          return_type: instance_type('String'),
        )
      end
    end

    context 'function type with params including generic types is given' do
      let(:type_string) { '(Integer, Array<Float>) -> Array<String>'}
      it do
        is_expected.to eq Yoda::Model::TypeExpressions::FunctionType.new(
          required_parameters: [instance_type('Integer'), generic_type(instance_type('Array'), instance_type('Float'))].map(&method(:parameter)),
          return_type: generic_type(instance_type('Array'), instance_type('String')),
        )
      end
    end

    context 'function type with params including block parameter is given' do
      let(:type_string) { '(Integer, &(Object) -> Float) -> String'}
      it do
        is_expected.to eq Yoda::Model::TypeExpressions::FunctionType.new(
          required_parameters: [instance_type('Integer')].map(&method(:parameter)),
          optional_parameters: [],
          block_parameter:
            parameter(
              Yoda::Model::TypeExpressions::FunctionType.new(
                required_parameters: [instance_type('Object')].map(&method(:parameter)),
                return_type: instance_type('Float'),
              ),
            ),
          return_type: instance_type('String'),
        )
      end
    end

    context 'function type with params including block parameter is given' do
      let(:type_string) { '(Integer, ?Numeric) -> String'}
      it do
        is_expected.to eq Yoda::Model::TypeExpressions::FunctionType.new(
          required_parameters: [instance_type('Integer')].map(&method(:parameter)),
          optional_parameters: [instance_type('Numeric')].map(&method(:parameter)),
          return_type: instance_type('String'),
        )
      end
    end

    context 'function type with params including block parameter is given' do
      let(:type_string) { '(Integer, *Array<Numeric>, Float, **Hash<Symbol, Object>) -> String'}
      it do
        is_expected.to eq Yoda::Model::TypeExpressions::FunctionType.new(
          required_parameters: [instance_type('Integer')].map(&method(:parameter)),
          rest_parameter: parameter(generic_type(instance_type('Array'), instance_type('Numeric'))),
          post_parameters: [instance_type('Float')].map(&method(:parameter)),
          keyword_rest_parameter: parameter(generic_type(instance_type('Hash'), instance_type('Symbol'), instance_type('Object'))),
          return_type: instance_type('String'),
        )
      end
    end
  end
end
