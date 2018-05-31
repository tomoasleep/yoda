require 'spec_helper'

RSpec.describe Yoda::Parsing::SourceAnalyzer do
  include TypeHelper
  include AST::Sexp

  describe '#nodes_to_current_location_from_root' do
    subject { described_class.from_source(source, location).nodes_to_current_location_from_root }

    context 'a class definition is given' do
      let(:source) do
        <<~EOS
        class Hoge
          def main(hoge)
            hoge.fu
          end

          def main2
            ConstName
          end
        end
        EOS
      end

      context 'when the cursor is on a send node' do
        let(:location) { Yoda::Parsing::Location.new(row: 3, column: 9) }

        it 'returns the type of the method' do
          expect(subject).to match([
            have_attributes(type: :class),
            have_attributes(type: :begin),
            have_attributes(type: :def, children: include(:main)),
            have_attributes(type: :send, children: include(:fu)),
          ])
        end
      end

      context 'when the cursor is on a single const node' do
        let(:location) { Yoda::Parsing::Location.new(row: 7, column: 9) }

        it 'returns the type of the method' do
          expect(subject).to match([
            have_attributes(type: :class),
            have_attributes(type: :begin),
            have_attributes(type: :def, children: include(:main2)),
            have_attributes(type: :const, children: include(:ConstName)),
          ])
        end
      end
    end
  end

  describe '#current_method_node' do
    subject { described_class.from_source(source, location).current_method_node }

    context 'a class definition is given' do
      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 10) }
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
        expect(subject).to have_attributes(type: :def, children: include(:main))
      end
    end
  end
end
