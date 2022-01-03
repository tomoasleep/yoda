require 'spec_helper'

RSpec.describe Yoda::Parsing::CommentTokenizer do
  include TypeHelper

  describe '.parse' do
    subject { described_class.new.parse(comment_line) }

    context 'a tag name is given' do
      let(:comment_line) { '@param' }
      it 'parses comment line' do
        expect(subject.length).to eq(1)
        sequence = subject.first
        expect(sequence.tag).to have_attributes(to_s: '@param')
      end
    end

    context 'a param tag and parameters are given' do
      let(:comment_line) { '@param hoge [' }
      it 'parses comment line' do
        expect(subject.length).to eq(1)
        sequence = subject.first
        expect(sequence.tag).to have_attributes(to_s: '@param')
        expect(sequence.parameter_tokens).to contain_exactly(
          have_attributes(to_s: 'hoge'),
          have_attributes(to_s: '['),
        )
      end
    end
  end
end
