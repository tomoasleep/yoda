require 'spec_helper'

RSpec.describe Yoda::Services::CurrentNodeExplain do
  let(:explain) { described_class.new(evaluator: evaluator, location: location) }

  let(:environment) { Yoda::Model::Environment.build }
  let(:ast) { Yoda::Parsing.parse_with_comments(source).first }
  let(:evaluator) { Yoda::Services::Evaluator.new(environment: project.environment, ast: ast) }
  let(:project) { Yoda::Store::Project.for_path(nil) }

  before do
    project.setup
    ReadSourceHelper.read_source(project: project, source: source) if source
  end

  describe '#current_comment_signature' do
    subject { explain.current_comment_signature }

    context 'when on a type part of comment' do
      let(:location) { Yoda::Parsing::Location.new(row: 2, column: 20) }
      let(:source) do
        <<~EOS
        class Hoge
          # @param hoge [String]
          def main(hoge)
            hoge.fu
          end
        end
        EOS
      end

      it 'returns a comment signature' do
        expect(subject).to be_a(Yoda::Services::CurrentNodeExplain::CommentSignature)
      end

      it 'contains information about the comment' do
        expect(subject.node_range).to have_attributes(begin_location: have_attributes(row: 2, column: 18), end_location: have_attributes(row: 2, column: 24))
        expect(subject.descriptions).to contain_exactly(
          have_attributes(title: 'String', markup_content: { language: 'ruby', value: 'String # singleton(::String)' }),
          have_attributes(title: 'String', markup_content: be_start_with("**String**")),
        )
        expect(subject.defined_files.length).to be(1)
      end
    end
  end
end
