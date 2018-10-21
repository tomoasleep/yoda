require 'spec_helper'

RSpec.describe Yoda::Commands::Evaluator do
  let(:evaluator) { described_class.from_ast(registry, ast, location) }
  let(:source) { File.read(File.expand_path(path, fixture_root)) }
  let(:source_string) { nil }
  let(:source_analyzer) { Yoda::Parsing::SourceAnalyzer.from_source(source_string || source, location) }
  let(:ast) { source_analyzer.ast }
  let(:current_node) { source_analyzer.nodes_to_current_location_from_root.last }

  let(:fixture_root) { File.expand_path('../../support/fixtures', __dir__) }
  let(:project) { Yoda::Store::Project.new(fixture_root) }
  let(:registry) { project.registry }
  before do
    project.build_cache
    ReadSourceHelper.read_source(project: project, source: source_string) if source_string
  end

  describe '#calculate_trace' do
    subject { evaluator.calculate_trace(current_node) }

    context 'when in a instance method definition' do
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

      context 'and on argument of keyword parameter' do
        let(:path) { 'lib/evaluator_spec_fixture.rb' }
        let(:location) { Yoda::Parsing::Location.new(row: 43, column: 56) }

        it 'returns evaluation result of send node' do
          expect(subject).to be_a(Yoda::Typing::Traces::Send)
          expect(subject).to have_attributes(
            type: Yoda::Model::Types::InstanceType.new(
              Yoda::Model::ScopedPath.new(['YodaFixture::EvaluatorSpecFixture', 'YodaFixture', 'Object'], 'String'),
            ),
          )
        end
      end
    end

    context 'when in a block' do
      context 'and on a constant node' do
        let(:path) { 'lib/dsl.rb' }
        let(:location) { Yoda::Parsing::Location.new(row: 9, column: 10) }

        it 'contains constant type' do
          expect(subject).to be_a(Yoda::Typing::Traces::Base)
          expect(subject).to have_attributes(
            type: Yoda::Model::Types::ModuleType.new('YodaFixture'),
          )
        end
      end
    end

    context 'when in a class definition' do
      let(:path) { 'lib/evaluator_spec_fixture.rb' }

      context 'and on a symbol node' do
        let(:location) { Yoda::Parsing::Location.new(row: 4, column: 20) }

        it 'contains symbol type' do
          expect(subject).to be_a(Yoda::Typing::Traces::Base)
          expect(subject).to have_attributes(
            type: Yoda::Model::Types::InstanceType.new('::Symbol'),
          )
        end
      end

      context 'and in a singleton method definition' do
        context 'and on a self node' do
          let(:location) { Yoda::Parsing::Location.new(row: 31, column: 9) }

          it 'contains type of self' do
            expect(subject).to be_a(Yoda::Typing::Traces::Base)
            expect(subject).to have_attributes(
              type: Yoda::Model::Types::ModuleType.new('YodaFixture::EvaluatorSpecFixture'),
            )
          end
        end

        context 'and on a variable node' do
          let(:location) { Yoda::Parsing::Location.new(row: 31, column: 20) }

          it 'contains type of the variable' do
            expect(subject).to be_a(Yoda::Typing::Traces::Base)
            expect(subject).to have_attributes(
              type: Yoda::Model::Types::InstanceType.new(
                Yoda::Model::ScopedPath.new(['YodaFixture::EvaluatorSpecFixture', 'YodaFixture', 'Object'], 'String'),
              ),
            )
          end
        end
      end
    end

    context 'when in a magic comment' do
      let(:path) { 'lib/evaluator_spec_fixture2.rb' }
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 0) }

      it 'returns nothing' do
        expect(subject).to be_falsy
      end
    end
  end
end
