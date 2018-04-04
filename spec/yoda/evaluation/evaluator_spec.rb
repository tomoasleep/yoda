require 'spec_helper'

RSpec.describe Yoda::Evaluation::Evaluator do
  let(:evaluator) { described_class.from_ast(registry, ast, location) }
  let(:source) { File.read(File.expand_path(path, fixture_root)) }
  let(:source_analyzer) { Yoda::Parsing::SourceAnalyzer.from_source(source, location) }
  let(:ast) { source_analyzer.ast }
  let(:current_node) { source_analyzer.nodes_to_current_location_from_root.last }

  let(:fixture_root) { File.expand_path('../../support/fixtures', __dir__) }
  let(:project) { Yoda::Store::Project.new(fixture_root) }
  let(:registry) { project.registry }
  before { project.setup }

  describe '#calculate_trace' do
    subject { evaluator.calculate_trace(current_node) }

    context 'request information on constant node in sample function' do
      let(:path) { 'lib/sample2.rb' }
      let(:location) { Yoda::Parsing::Location.new(row: 23, column: 10) }

      it 'returns evaluation result of constant node' do
        expect(subject).to be_a(Yoda::Typing::Traces::Base)
        expect(subject).to have_attributes(
          type: Yoda::Model::Types::ModuleType.new('YodaFixture::Sample2'),
        )
      end
    end

    context 'request information on send node in sample function' do
      let(:path) { 'lib/sample2.rb' }
      let(:location) { Yoda::Parsing::Location.new(row: 27, column: 10) }

      it 'returns evaluation result of send node' do
        expect(subject).to be_a(Yoda::Typing::Traces::Send)
        expect(subject).to have_attributes(
          type: Yoda::Model::Types::InstanceType.new(
            Yoda::Model::ScopedPath.new(['YodaFixture::Sample2', 'YodaFixture', 'Object'], 'YodaFixture::Sample2')
          ),
        )
      end
    end

    context 'when in a block' do
      context 'and on a constant node' do
        let(:path) { 'lib/dsl.rb' }
        let(:location) { Yoda::Parsing::Location.new(row: 9, column: 10) }

        it 'returns evaluation result of send node' do
          expect(subject).to be_a(Yoda::Typing::Traces::Base)
          expect(subject).to have_attributes(
            type: Yoda::Model::Types::ModuleType.new('YodaFixture'),
          )
        end
      end
    end
  end
end
