require 'spec_helper'

RSpec.xdescribe Yoda::Parsing::Scopes::Builder do
  let(:builder) { described_class.new(ast) }
  let(:ast) { Yoda::Parsing::Parser.new.parse(source) }

  describe '#root_scope' do
    subject { described_class.new(ast).root_scope }

    context 'when a method definition on root is given' do
      let(:source) do
        <<~EOS
        def method1
        end
        EOS
      end

      it 'contains a method definition object' do
        expect(subject.method_definitions).to contain_exactly(
          have_attributes(name: :method1),
        )
      end
    end

    context 'when a empty singleton class definition on root is given' do
      let(:source) do
        <<~EOS
        class << self
        end
        EOS
      end

      it 'contains a class definition object' do
        expect(subject.child_scopes).to contain_exactly(
          have_attributes(kind: :meta_class),
        )
      end
    end

    context 'when a empty class definition on root is given' do
      let(:source) do
        <<~EOS
        class Klass1
        end
        EOS
      end

      it 'contains a class definition object' do
        expect(subject.child_scopes).to contain_exactly(
          have_attributes(
            const_node: have_attributes(to_s: 'Klass1'),
          ),
        )
      end
    end

    context 'when a empty module definition on root is given' do
      let(:source) do
        <<~EOS
        module Module1
        end
        EOS
      end

      it 'contains a module definition object' do
        expect(subject.child_scopes).to contain_exactly(
          have_attributes(
            const_node: have_attributes(to_s: 'Module1'),
          ),
        )
      end
    end

    context 'when a class definition with a method definition on root is given' do
      let(:source) do
        <<~EOS
        class Klass1
          def method1
          end
        end
        EOS
      end

      it 'contains a class definition object with a method defition' do
        expect(subject.child_scopes).to contain_exactly(
          have_attributes(
            const_node: have_attributes(to_s: 'Klass1'),
            method_definitions: contain_exactly(
              have_attributes(name: :method1),
            ),
          ),
        )
      end
    end

    context 'when a class definition with a method definition and a property definition is given' do
      let(:source) do
        <<~EOS
        class Klass1
          attr_reader :property1

          def method1
          end
        end
        EOS
      end

      it 'contains a class definition object with a method defition' do
        expect(subject.child_scopes).to contain_exactly(
          have_attributes(
            const_node: have_attributes(to_s: 'Klass1'),
            method_definitions: contain_exactly(
              have_attributes(name: :method1),
            ),
          ),
        )
      end
    end

    context 'when a class definition with a singleton method definition and a property definition is given' do
      let(:source) do
        <<~EOS
        class Klass1
          def self.method1
          end
        end
        EOS
      end

      it 'contains a class definition object with a method defition' do
        expect(subject.child_scopes).to contain_exactly(
          have_attributes(
            const_node: have_attributes(to_s: 'Klass1'),
            method_definitions: contain_exactly(
              have_attributes(name: :method1, kind: :meta_method),
            ),
          ),
        )
      end
    end

    context 'when nested module definition on root is given' do
      let(:source) do
        <<~EOS
        module Module1
          module Module2
          end
        end
        EOS
      end

      it 'contains a module definition object' do
        expect(subject.child_scopes).to contain_exactly(
          have_attributes(
            const_node: have_attributes(to_s: 'Module1'),
            child_scopes: contain_exactly(
              have_attributes(
                const_node: have_attributes(to_s: 'Module2'),
              ),
            ),
          ),
        )
      end
    end
  end
end
