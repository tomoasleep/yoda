
require 'spec_helper'

RSpec.describe Yoda::Services::CodeCompletion::MethodProvider do
  let(:provider) { described_class.new(project.environment, ast, location, evaluator) }

  let(:project) { Yoda::Store::Project.for_path(nil) }
  let(:ast) { Yoda::Parsing.parse(source) }
  let(:evaluator) { Yoda::Services::Evaluator.new(environment: project.environment, ast: ast) }

  before do
    project.setup
    ReadSourceHelper.read_source(project: project, source: source) if source
  end

  def range(b, e)
    b_row, b_column = b
    e_row, e_column = e
    have_attributes(
      begin_location: have_attributes(row: b_row, column: b_column),
      end_location: have_attributes(row: e_row, column: e_column),
    )
  end

  describe '#candidates' do
    subject { provider.candidates }

    context 'on top level' do
      context 'with method definition on top level' do
        let(:location) { Yoda::Parsing::Location.new(row: 2, column: 4) }
        let(:source) do
          <<~EOS
          def sample; end
          samp
          EOS
        end

        it 'returns the matched instance methods of Object' do
          expect(subject).to contain_exactly(
            have_attributes(edit_text: 'sample', title: 'Object#sample() -> untyped', range: range([2, 0], [2, 4])),
          )
        end

        it 'marks the method low priority' do
          expect(subject).to contain_exactly(
            have_attributes(edit_text: 'sample', sort_text: '~sample'),
          )
        end
      end

      context 'with instance method definition in a class definition' do
        let(:location) { Yoda::Parsing::Location.new(row: 5, column: 20) }
        let(:source) do
          <<~EOS
          class YodaFixture
            def initialize; end
            def sample; end
          end
          YodaFixture.new.samp
          EOS
        end

        it 'returns the matched instance methods of Object' do
          expect(subject).to contain_exactly(
            have_attributes(edit_text: 'sample', title: 'YodaFixture#sample() -> untyped', range: range([5, 16], [5, 20])),
          )
        end
      end

      context 'with class method definition in a class definition' do
        let(:location) { Yoda::Parsing::Location.new(row: 4, column: 16) }
        let(:source) do
          <<~EOS
          class YodaFixture
            def self.sample; end
          end
          YodaFixture.samp
          EOS
        end

        it 'returns the matched instance methods of Object' do
          expect(subject).to contain_exactly(
            have_attributes(edit_text: 'sample', title: 'YodaFixture.sample() -> untyped', range: range([4, 12], [4, 16])),
          )
        end
      end
    end
  end
end
