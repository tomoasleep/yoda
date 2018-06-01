require 'spec_helper'

RSpec.describe Yoda::Parsing::Query::CurrentCommentTokenQuery do
  let(:query) { Yoda::Parsing::Query::CurrentCommentTokenQuery.new(comment, location) }
  let(:comment) do
    <<~EOS.gsub(/^#/, '')
    # @param hoge [Hoge::Fuga] the hoge number.
    EOS
  end

  describe '#current_state' do
    subject { query.current_state }

    context 'when after at-mark' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 2) }
      it { is_expected.to be(:tag) }
    end

    context 'when on tag name' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 3) }
      it { is_expected.to be(:tag) }
    end

    context 'when on param name' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 9) }
      it { is_expected.to be(:param) }
    end

    context 'when after left bracket' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 14) }
      it { is_expected.to be(:type) }
    end

    context 'when on type name' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 15) }
      it { is_expected.to be(:type) }
    end

    context 'when after double collon' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 20) }
      it { is_expected.to be(:type) }
    end
  end

  describe '#current_range' do
    subject { query.current_range }

    context 'when after at-mark' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 2) }
      it 'covers beginning of tag and cursor' do
         is_expected.to have_attributes(
           begin_location: have_attributes(row: 1, column: 1),
           end_location: have_attributes(row: 1, column: 2),
        )
      end
    end

    context 'when on tag name' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 3) }
      it 'covers beginning of tag and cursor' do
         is_expected.to have_attributes(
           begin_location: have_attributes(row: 1, column: 1),
           end_location: have_attributes(row: 1, column: 3),
        )
      end
    end

    context 'when on param name' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 9) }
      it 'covers beginning of param and cursor' do
         is_expected.to have_attributes(
           begin_location: have_attributes(row: 1, column: 8),
           end_location: have_attributes(row: 1, column: 9),
        )
      end
    end

    context 'when after left bracket' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 14) }
      it 'covers beginning of param and cursor' do
         is_expected.to have_attributes(
           begin_location: have_attributes(row: 1, column: 13),
           end_location: have_attributes(row: 1, column: 14),
        )
      end
    end

    context 'when on type name' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 15) }
      it 'covers beginning of param and cursor' do
         is_expected.to have_attributes(
           begin_location: have_attributes(row: 1, column: 14),
           end_location: have_attributes(row: 1, column: 15),
        )
      end
    end

    context 'when after double collon' do
      let(:location) { Yoda::Parsing::Location.new(row: 1, column: 20) }
      it 'covers beginning of param and cursor' do
         is_expected.to have_attributes(
           begin_location: have_attributes(row: 1, column: 14),
           end_location: have_attributes(row: 1, column: 20),
        )
      end
    end
  end
end
