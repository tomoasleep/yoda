require 'spec_helper'

RSpec.describe Yoda::Services::Evaluator do
  let(:evaluator) { described_class.new(environment: project.environment, ast: ast) }
  let(:source) { File.read(File.expand_path(path, fixture_root)) }
  let(:source_string) { nil }
  let(:ast) { Yoda::Parsing::Parser.new.parse(source_string || source) }
  let(:current_node) { ast.positionally_nearest_child(location) }

  let(:fixture_root) { File.expand_path('../../support/fixtures', __dir__) }
  let(:project) { Yoda::Store::Project.for_path(fixture_root) }

  before do
    project.setup
    ReadSourceHelper.read_source(project: project, source: source_string) if source_string
  end

  describe '#type' do
    subject { evaluator.type(current_node) }

    context 'when in a instance method definition' do
      context 'request information on constant node in sample function' do
        let(:path) { 'lib/sample2.rb' }
        let(:location) { Yoda::Parsing::Location.new(row: 23, column: 10) }

        it 'returns evaluation result of constant node' do
          expect(subject.to_s).to eq('singleton(::YodaFixture::Sample2)')
        end
      end
    end

    context 'when in a block' do
      context 'and on a constant node' do
        let(:path) { 'lib/dsl.rb' }
        let(:location) { Yoda::Parsing::Location.new(row: 9, column: 10) }

        it 'contains constant type' do
          expect(subject.to_s).to eq('singleton(::YodaFixture)')
        end
      end
    end

    context 'when in a class definition' do
      let(:path) { 'lib/evaluator_spec_fixture.rb' }

      context 'and on a symbol node' do
        let(:location) { Yoda::Parsing::Location.new(row: 4, column: 20) }

        it 'contains symbol type' do
          expect(subject.to_s).to eq(':content')
        end
      end

      context 'and in a singleton method definition' do
        context 'and on a self node' do
          let(:location) { Yoda::Parsing::Location.new(row: 31, column: 9) }

          it 'contains type of self' do
            expect(subject.to_s).to eq('singleton(::YodaFixture::EvaluatorSpecFixture)')
          end
        end

        context 'and on a variable node' do
          let(:location) { Yoda::Parsing::Location.new(row: 31, column: 20) }

          it 'contains type of the variable' do
            expect(subject.to_s).to eq("::String")
          end
        end
      end
    end

    context 'on send node' do
      context 'request information on send node in sample function' do
        let(:path) { 'lib/sample2.rb' }
        let(:location) { Yoda::Parsing::Location.new(row: 27, column: 10) }

        it 'returns evaluation result of send node' do
          expect(subject.to_s).to eq('::YodaFixture::Sample2')
        end
      end

      context 'and on argument of keyword parameter' do
        let(:path) { 'lib/evaluator_spec_fixture.rb' }
        let(:location) { Yoda::Parsing::Location.new(row: 43, column: 56) }

        it 'returns evaluation result of send node' do
          expect(subject.to_s).to eq("::String")
        end
      end
    end
  end
end
