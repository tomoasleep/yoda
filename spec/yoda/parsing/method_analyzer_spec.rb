require 'spec_helper'

RSpec.describe Yoda::Parsing::MethodAnalyzer do
  include TypeHelper

  let(:registry) { Yoda::Store::Registry.instance }
  let(:root) { registry.at(:root) }

  shared_context 'define a class to root' do
    let!(:class_object) do
      YARD::CodeObjects::ClassObject.new(root, 'Hoge') do |klass|
        YARD::CodeObjects::MethodObject.new(klass, 'main') do |obj|
          obj.docstring = "@param hoge [Hoge]"
          obj.parameters = [['hoge', nil]]
        end
        YARD::CodeObjects::MethodObject.new(klass, 'fuga') do |obj|
          obj.docstring = "@return [String]"
        end
      end
    end
  end

  describe '#complete' do
    subject { described_class.from_source(registry, source, location).complete }

    context 'a class definition is given' do
      include_context 'define a class to root'

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

      it 'returns the matched method' do
        expect(subject).to contain_exactly(have_attributes(path: 'Hoge#fuga'))
      end
    end

    context 'a class definition is given' do
      include_context 'define a class to root'

      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 10) }
      let(:source) do
        <<~EOS
        class Hoge
          def main(hoge)
            hoge.fuho
          end
        end
        EOS
      end

      it 'respects the current cursor and returns the matched method' do
        expect(subject).to contain_exactly(have_attributes(path: 'Hoge#fuga'))
      end
    end
  end

  describe '#calculate_current_node_type' do
    subject { described_class.from_source(registry, source, location).calculate_current_node_type }

    context 'on local variable' do
      include_context 'define a class to root'

      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 4) }
      let(:source) do
        <<~EOS
        class Hoge
          def main(hoge)
            hoge.fu
          end
        end
        EOS
      end

      it 'returns the variable type' do
        expect(subject).to eq(instance_type('Hoge'))
      end
    end

    context 'on method call' do
      include_context 'define a class to root'

      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 10) }
      let(:source) do
        <<~EOS
        class Hoge
          def main(hoge)
            hoge.fuga
          end
        end
        EOS
      end

      it 'returns the return value type' do
        expect(subject).to eq(instance_type('String'))
      end
    end
  end
end
