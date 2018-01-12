require 'spec_helper'

RSpec.describe Yoda::Parsing::SourceCutter do
  describe '#error_recovered_source' do
    subject { described_class.new(source, location).error_recovered_source }

    context 'cut on method name' do
      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 11) }
      let(:source) do
        <<~EOS
        class Hoge
          def main(hoge)
            hoge.fu
          end
        end
        EOS
      end

      it 'returns the type of the method' do
        expect(subject).to eq(
          <<~EOS.chomp
          class Hoge
            def main(hoge)
              hoge.fu
          ;
          end
          end
          EOS
        )
      end
    end

    context 'cut on dot' do
      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 9) }
      let(:source) do
        <<~EOS
        class Hoge
          def main(hoge)
            hoge.fu
          end
        end
        EOS
      end

      it 'returns the type of the method' do
        expect(subject).to eq(
          <<~EOS.chomp
          class Hoge
            def main(hoge)
              hoge.
          dummy_method
          ;
          end
          end
          EOS
        )
      end
    end

    context 'cut on dot' do
      subject { require 'pry'; Pry::rescue{ described_class.new(source, location).error_recovered_source } }
      let(:location) { Yoda::Parsing::Location.new(row: 32, column: 10) }
      let(:source) do
        <<~EOS
        module Yoda
          module Parsing
            class Range
              attr_reader :begin_location, :end_location
              # @param begin_location [Integer]
              # @param end_location   [Integer]
              def initialize(begin_location, end_location)
                @begin_location = begin_location
                @end_location = end_location
              end

              # @param ast_location [Parser::Source::Map, Parser::Source::Range]
              # @return [Location, nil]
              def self.of_ast_location(ast_location)
                return nil unless Location.valid_location?(ast_location)
                new(
                  Location.new(row: ast_location.line, column: ast_location.column),
                  Location.new(row: ast_location.last_line, column: ast_location.last_column),
                )
              end

              # @return [{Symbol => { Symbol => Integer } }]
              def to_language_server_protocol_range
                { start: begin_location.to_language_server_protocol_range, end: end_location.to_language_server_protocol_range }
              end

              # @param row    [Integer]
              # @param column [Integer]
              # @return [Range]
              def move(row:, column:)
                self.class.new(begin_location.move(row: row, column: column), end_location.move(row: row, column: column))
                Range
              end
            end
          end
        end
        EOS
      end

      it 'returns the type of the method' do
        expect(subject).to eq(
          <<~EOS.chomp
          module Yoda
            module Parsing
              class Range
                attr_reader :begin_location, :end_location
                # @param begin_location [Integer]
                # @param end_location   [Integer]
                def initialize(begin_location, end_location)
                  @begin_location = begin_location
                  @end_location = end_location
                end

                # @param ast_location [Parser::Source::Map, Parser::Source::Range]
                # @return [Location, nil]
                def self.of_ast_location(ast_location)
                  return nil unless Location.valid_location?(ast_location)
                  new(
                    Location.new(row: ast_location.line, column: ast_location.column),
                    Location.new(row: ast_location.last_line, column: ast_location.last_column),
                  )
                end

                # @return [{Symbol => { Symbol => Integer } }]
                def to_language_server_protocol_range
                  { start: begin_location.to_language_server_protocol_range, end: end_location.to_language_server_protocol_range }
                end

                # @param row    [Integer]
                # @param column [Integer]
                # @return [Range]
                def move(row:, column:)
                  self.class.new(begin_location.move(row: row, column: column), end_location.move(row: row, column: column))
                  Range
          ;
          end
          end
          end
          end
          EOS
        )
      end
    end
  end
end
