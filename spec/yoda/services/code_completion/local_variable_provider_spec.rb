require 'spec_helper'

RSpec.describe Yoda::Services::CodeCompletion::LocalVariableProvider do
  let(:provider) { described_class.new(environment, ast, location, evaluator) }

  let(:environment) { Yoda::Model::Environment.build }
  let(:ast) { Yoda::Parsing.parse(source) }
  let(:evaluator) { Yoda::Services::Evaluator.new(environment: environment, ast: ast) }

  describe '#candidates' do
    subject { provider.candidates }

    context 'in top level' do
      let(:location) { Yoda::Parsing::Location.new(row: 5, column: 4) }
      let(:source) do
        <<~EOS
        variable_a = 1
        variable_b = variable_a
        variable_c = "string"
        different_variable = 2
        vari
        EOS
      end

      it 'returns the matched variables' do
        expect(subject).to contain_exactly(
          have_attributes(edit_text: 'variable_a', title: 'variable_a: 1'),
          have_attributes(edit_text: 'variable_b', title: 'variable_b: 1'),
          have_attributes(edit_text: 'variable_c', title: 'variable_c: "string"'),
        )
      end
    end
  end
end
