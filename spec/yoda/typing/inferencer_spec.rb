require 'spec_helper'

RSpec.describe Yoda::Typing::Inferencer do
  include AST::Sexp

  let(:registry) { Yoda::Store::Registry.new(Yoda::Store::Adapters::MemoryAdapter.new) }
  let(:receiver_type) { Yoda::Typing::Types::Instance.new(klass: registry.get('Object')) }
  let(:context) { Yoda::Typing::Inferencer::NamespaceContext.root_scope(registry) }

  let(:inferencer) { described_class.new(context: context) }

  let(:patch) do
    Yoda::Store::Objects::Patch.new(:test).tap do |patch|
      objects.each { |object| patch.register(object) }
    end
  end
  before { registry.add_patch(patch) }

  let(:objects) do
    [
      Yoda::Store::Objects::ClassObject.new(
        path: 'Integer',
        superclass_path: 'Object',
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Integer#+',
        parameters: [['another', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Integer']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'another', yard_types: ['Integer']),
        ],
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Integer#-',
        parameters: [['another', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Integer']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'another', yard_types: ['Integer']),
        ],
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Integer#*',
        parameters: [['another', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Integer']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'another', yard_types: ['Integer']),
        ],
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Integer#modulo',
        parameters: [['another', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Integer']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'another', yard_types: ['Integer']),
        ],
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Integer#div',
        parameters: [['another', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Integer']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'another', yard_types: ['Integer']),
        ],
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Integer#<',
        parameters: [['another', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Boolean']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'another', yard_types: ['Integer']),
        ],
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Integer.sqrt',
        parameters: [['n', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Integer']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'n', yard_types: ['Integer']),
        ],
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Object#tap',
        parameters: [['&block', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['self']),
          Yoda::Store::Objects::Tag.new(tag_name: 'yield', yard_types: ['object']),
          Yoda::Store::Objects::Tag.new(tag_name: 'yieldparam', name: 'object', yard_types: ['self']),
        ],
      ),
    ]
  end
  let(:integer) do
    Yoda::Store::Objects::ClassObject.new(path: 'Integer')
  end

  describe '#infer' do
    let(:ast) { Yoda::Parsing::Parser.new.parse(source) }
    let(:node_traverser) { Yoda::Parsing::Traverser.new(ast) }
    subject { inferencer.infer(ast) }

    context 'only an integer' do
      let(:source) do
        <<~RUBY
          1
        RUBY
      end

      it 'returns the type of the method' do
        expect(subject).to have_attributes(
          klass: have_attributes(
            path: 'Integer',
          )
        )
      end
    end

    context 'send + to an integer' do
      let(:source) do
        <<~RUBY
          1 + 1
        RUBY
      end

      it 'returns the type of the method' do
        expect(subject).to have_attributes(
          klass: have_attributes(
            path: 'Integer',
          )
        )
      end
    end

    context 'class constant' do
      let(:source) do
        <<~RUBY
          Integer
        RUBY
      end

      it 'returns the type of the class' do
        expect(subject).to have_attributes(
          klass: have_attributes(
            path: 'Integer',
            kind: :meta_class,
          )
        )
      end
    end

    context 'send sqrt to Integer constant' do
      let(:source) do
        <<~RUBY
          Integer.sqrt(1)
        RUBY
      end

      it 'returns the type of the method' do
        expect(subject).to have_attributes(
          klass: have_attributes(
            path: 'Integer',
          )
        )
      end
    end

    context 'class context' do
      context 'send sqrt to Integer constant' do
        let(:source) do
          <<~RUBY
            class Integer
              sqrt(3)
            end
          RUBY
        end

        it 'returns the type of the method' do
          subject
          expect(inferencer.tracer.method_candidates(node_traverser.query(type: :send).node)).to contain_exactly(
            have_attributes(
              name: 'sqrt'
            )
          )
        end
      end

      context 'define modulo in Integer class' do
        let(:source) do
          <<~RUBY
            class Integer
              def modulo(n)
                if n > 0
                  multipled_quotient = div(n) * n
                  self - multipled_quotient
                end
              end
            end
          RUBY
        end

        it 'binds the type of the argument variable' do
          subject
          expect(inferencer.tracer.type(node_traverser.query(type: :lvar, name: :n).node)).to have_attributes(
            klass: have_attributes(
              path: 'Integer',
              kind: :class,
            )
          )
          expect(inferencer.tracer.type(node_traverser.query(type: :lvar, name: :multipled_quotient).node)).to have_attributes(
            klass: have_attributes(
              path: 'Integer',
              kind: :class,
            )
          )
        end

        it 'binds the type of self' do
          subject
          expect(inferencer.tracer.type(node_traverser.query(type: :self).node)).to have_attributes(
            klass: have_attributes(
              path: 'Integer',
              kind: :class,
            )
          )
        end

        it 'binds method types' do
          subject
          expect(inferencer.tracer.method_candidates(node_traverser.query(type: :send, name: :div).node)).to contain_exactly(
            have_attributes(
              name: 'div',
              namespace_path: 'Integer',
            )
          )
          expect(inferencer.tracer.method_candidates(node_traverser.query(type: :send, name: :*).node)).to contain_exactly(
            have_attributes(
              name: '*',
              namespace_path: 'Integer',
            )
          )
          expect(inferencer.tracer.method_candidates(node_traverser.query(type: :send, name: :-).node)).to contain_exactly(
            have_attributes(
              name: '-',
              namespace_path: 'Integer',
            )
          )
        end

        it 'binds contexts' do
          subject
          expect(inferencer.tracer.context_variable_types(node_traverser.query(type: :class).node)).to be_empty
          expect(inferencer.tracer.context_variable_types(node_traverser.query(type: :def, name: :modulo).node)).to be_empty
          expect(inferencer.tracer.context_variable_types(node_traverser.query(type: :send, name: :-).node)).to a_hash_including(
            n: have_attributes(path: Yoda::Model::ScopedPath.build('Integer')),
            multipled_quotient: have_attributes(path: Yoda::Model::ScopedPath.build('Integer')),
          )
        end
      end
    end
  end
end
