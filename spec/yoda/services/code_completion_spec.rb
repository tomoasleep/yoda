require 'spec_helper'

RSpec.xdescribe Yoda::Services::CodeCompletion do
  include TypeHelper

  let(:service) { described_class.new(environment, source, location) }
  let(:environment) { Model::Environment.build }
  let(:root) { environment.registry.at(:root) }

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


  describe '#method_candidates' do
    subject { service.method_candidates }

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

    context 'a class definition is given and cursor is on the dot' do
      include_context 'define a class to root'

      let(:location) { Yoda::Parsing::Location.new(row: 3, column: 8) }
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
        expect(subject).to contain_exactly(have_attributes(path: 'Hoge#main'), have_attributes(path: 'Hoge#fuga'))
      end
    end
  end
end
