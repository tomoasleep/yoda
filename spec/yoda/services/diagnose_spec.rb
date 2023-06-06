require 'spec_helper'

RSpec.describe Yoda::Services::Diagnose do
  let(:service) { described_class.new(evaluator: evaluator) }
  let(:environment) { Model::Environment.build }
  let(:ast) { Yoda::Parsing.parse_with_comments(source).first }
  let(:evaluator) { Yoda::Services::Evaluator.new(environment: project.environment, ast: ast) }
  let(:project) { Yoda::Store::Project.for_path(nil) }

  before do
    project.setup
    ReadSourceHelper.read_source(project: project, source: source) if source
  end

  describe '#diagnostics' do
    subject { service.diagnostics }

    context 'when on a type part of comment' do
      let(:source) do
        <<~RUBY
          Object.unknown_method
        RUBY
      end

      it 'returns MethodNotFound diagnostics' do
        expect(subject).to contain_exactly(
          have_attributes(
            message: '`unknown_method` method is not found in `singleton(::Object)` type',
            range: have_attributes(
              begin_location: have_attributes(column: 0, row: 1),
              end_location: have_attributes(column: 21, row: 1),
            )
          )
        )
      end
    end
  end
end
