require 'spec_helper'

RSpec.xdescribe Yoda::Services::CodeCompletion::LocalVariableProvider do
  include TypeHelper

  let(:provider) { described_class.new(registry, source_analyzer) }
  let(:registry) { Yoda::Store::Registry.instance }
  let(:source_analyzer) { Yoda::Parsing::SourceAnalyzer.from_source(source, location) }

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
          have_attributes(name: 'varaible_a'),
          have_attributes(name: 'varaible_b'),
          have_attributes(name: 'varaible_c'),
        )
      end
    end
  end
end
