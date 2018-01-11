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
  end
end
