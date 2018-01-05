require 'spec_helper'

RSpec.describe Yoda::Parsing::MethodAnalyzer do
  include TypeHelper
  include AST::Sexp

  let(:registry) { Yoda::Store::Registry.instance }
  let(:root) { registry.at(:root) }

  shared_context 'define a class to root' do
    let!(:class_object) do
      YARD::CodeObjects::ClassObject.new(root, 'Hoge') do |klass|
        YARD::CodeObjects::MethodObject.new(klass, 'main') do |obj|
          obj.docstring = "@return [Hoge]"

        end
        YARD::CodeObjects::MethodObject.new(klass, 'fuga')
      end
    end
  end

  describe '#complete' do
    subject { described_class.from_source(registry, source, location).complete }

    context 'only an method send' do
      include_context 'define a class to root'

      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 10) }
      let(:source) do
        <<-EOS
        class Hoge
          def main(hoge)
            hoge.fu
          end
        end
        EOS
      end

      it 'returns the type of the method' do
        expect(subject).to contain_exactly(path: 'Hoge#fuga')
      end
    end
  end
end
