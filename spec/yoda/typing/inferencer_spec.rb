require 'spec_helper'
require 'tempfile'

RSpec.describe Yoda::Typing::Inferencer do
  include AST::Sexp
  include AddressHelper

  let(:environment) { Yoda::Model::Environment.build }
  let(:registry) { environment.registry }
  let(:receiver_type) { Yoda::Typing::Types::Instance.new(klass: registry.get('Object')) }

  let(:inferencer) { described_class.create_for_root(environment: environment) }

  let(:patch) do
    Yoda::Store::Objects::Patch.new(:test).tap do |patch|
      objects.each { |object| patch.register(object) }
    end
  end
  before { registry.local_store.add_file_patch(patch) }

  def read_source(source)
    Tempfile.create do |file|
      file.write(source)
      file.close
      Yoda::Store::Actions::ReadFile.new(file.path).run_and_register(registry)
    end
  end

  let(:objects) do
    [
      Yoda::Store::Objects::ClassObject.new(
        path: 'Object',
        mixin_addresses: addresses("Kernel"),
      ),
      # Inferencer requires metaclass to search constants
      Yoda::Store::Objects::MetaClassObject.new(
        path: 'Object',
      ),
      Yoda::Store::Objects::MethodObject.new(
        path: 'Kernel#require',
        parameters: [['path', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'path', yard_types: ['String']),
        ],
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'Integer',
        superclass_path: 'Object',
      ),
      # Inferencer requires metaclass to search constants
      Yoda::Store::Objects::MetaClassObject.new(
        path: 'Integer',
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
      Yoda::Store::Objects::MethodObject.new(
        path: 'Object#is_a?',
        parameters: [['mod', nil]],
        tag_list: [
          Yoda::Store::Objects::Tag.new(tag_name: 'return', yard_types: ['Boolean']),
          Yoda::Store::Objects::Tag.new(tag_name: 'param', name: 'mod', yard_types: ['Module']),
        ],
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'NilClass',
        superclass_path: 'Object',
      ),
      # Inferencer requires metaclass to search constants
      Yoda::Store::Objects::MetaClassObject.new(
        path: 'NilClass',
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'String',
        superclass_path: 'Object',
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'Module',
        superclass_path: 'Object',
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'TrueClass',
        superclass_path: 'Object',
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'FalseClass',
        superclass_path: 'Object',
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'Exception',
        superclass_path: 'Object',
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'StandardError',
        superclass_path: 'Exception',
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

      it 'returns the type of the literal' do
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

    describe 'instance method call' do
      context 'when the method returns self' do
        let(:source) do
          <<~RUBY
          1.tap
          RUBY
        end

        it "returns the receiver's type" do
          pending("Fow now, type is resolved as self")
          expect(subject).to have_attributes(to_s: "1")
        end

        it "resolves the constant as receiver's constant" do
          expect(subject.klass).to have_attributes(path: "Integer")
        end
      end
    end

    describe 'constant' do
      context 'with unknown constant' do
        let(:source) do
          <<~RUBY
            Unknwon
          RUBY
        end

        it 'returns the type of the class' do
          expect(subject).to have_attributes(to_s: "untyped")
        end
      end

      context 'with known class constant' do
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

      context 'with constant code with base prefix' do
        let(:source) do
          <<~RUBY
            ::Integer
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

      context 'with constant code with base prefix' do
        let(:source) do
          <<~RUBY
            ::Integer
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

      context 'with constant code with code prefix' do
        let(:source) do
          <<~RUBY
            obj = Object
            obj::Integer
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
            n: have_attributes(to_s: "::Integer"),
            multipled_quotient: have_attributes(to_s: "::Integer"),
          )
        end
      end
    end

    context 'singleton class context' do
      context 'send sqrt to Integer constant' do
        let(:source) do
          <<~RUBY
            class << Integer
              def sqrt(n)
                self
              end
            end
          RUBY
        end

        it 'returns nil type' do
          expect(subject).to have_attributes(
            klass: have_attributes(
              path: 'NilClass',
              kind: :class
            )
          )
        end

        it 'binds metaclass type to the type of self' do
          subject
          expect(inferencer.tracer.type(node_traverser.query(type: :self).node)).to have_attributes(
            klass: have_attributes(
              path: 'Integer',
              kind: :meta_class,
            )
          )
        end
      end
    end

    describe 'block calls' do
      context 'in block context of instance method' do
        let(:source) do
          <<~RUBY
          a = 2
          1.tap { |i| i + a }
          RUBY
        end

        xit 'binds the type of the block argument' do
          subject
          node = node_traverser.query(type: :lvar, name: :i).node
          expect(inferencer.tracer.type(node)).to have_attributes(to_s: '1')
        end

        it 'can infer variable defined from outer context' do
          subject
          node = node_traverser.query(type: :lvar, name: :a).node
          expect(inferencer.tracer.type(node)).to have_attributes(to_s: '2')
        end
      end
    end

    describe 'class method calls' do
      context 'in instance method context' do
        context 'call class method in method' do
          let(:source) do
            <<~RUBY
              class Integer
                def modulo(n)
                  Integer.sqrt(n)
                end
              end
            RUBY
          end

          it 'binds return type of the class method' do
            subject
            node = node_traverser.query(type: :send).node
            expect(inferencer.tracer.type(node)).to have_attributes(to_s: "::Integer")
          end

          it 'binds method candidates with parameter name' do
            subject
            node = node_traverser.query(type: :send).node
            expect(inferencer.tracer.method_candidates(node)).to contain_exactly(
              have_attributes(to_s: "sqrt(::Integer n) -> ::Integer"),
            )
          end
        end
      end
    end

    describe 'super calls' do
      context 'in instance method context' do
        context 'call class method in method' do
          let(:source) do
            <<~RUBY
              class Integer
                def is_a?(mod)
                  super(mod)
                end
              end
            RUBY
          end

          pending 'binds return type of the method of the superclass' do
            subject
            node = node_traverser.query(type: :super).node
            expect(inferencer.tracer.type(node)).to have_attributes(to_s: "::TrueClass | ::FalseClass")
          end

          it 'does not fails' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end

    describe 'subclass' do
      before do
        # sub class is not pre-defined
        read_source(source)
      end

      context 'call class method in method' do
        let(:source) do
          <<~RUBY
            class SubInteger < Integer
              def div(int)
                int / 2
              end
            end
          RUBY
        end

        it 'binds return type of the superclass' do
          subject
          node = node_traverser.query(type: :class).node
          expect(inferencer.tracer.type(node.super_class)).to have_attributes(to_s: "singleton(::Integer)")
        end

        pending 'binds argument types of an inherited method' do
          subject
          node = node_traverser.query(type: :send).node
          expect(inferencer.tracer.type(node.receiver)).to have_attributes(to_s: "::Integer")
        end
      end
    end

    describe 'operators' do
      describe 'with or operator' do
        let(:source) do
          <<~RUBY
          1 || "string"
          RUBY
        end

        it 'returns' do
          expect(subject).to have_attributes(to_s: '1 | "string"')
        end
      end

      describe 'with or operator' do
        let(:source) do
          <<~RUBY
          1 && "string"
          RUBY
        end

        it 'returns' do
          expect(subject).to have_attributes(to_s: '1 | "string"')
        end
      end
    end

    describe 'hash literal' do
      describe 'with symbol keys' do
        let(:source) do
          <<~RUBY
          { key: :value, another_key: "hoge", key2: 1 }
          RUBY
        end

        it 'returns a record type with symbol key' do
          # RBS's type does not use shorthand key expression if the key includes number.
          expect(subject).to have_attributes(to_s: '{ key: :value, another_key: "hoge", :key2 => 1 }')
        end
      end

      describe 'with string keys' do
        let(:source) do
          <<~RUBY
          { "key" => :value, "key2" => 1 }
          RUBY
        end

        it 'returns a record type with string key' do
          expect(subject).to have_attributes(to_s: '{ "key" => :value, "key2" => 1 }')
        end
      end
    end

    describe 'constant' do
      context 'with a not nested constant' do
        context 'a class is given' do
          let(:source) do
            <<~RUBY
            Integer
            RUBY
          end

          it 'returns singleton class' do
            expect(subject).to have_attributes(to_s: 'singleton(::Integer)')
          end

          it 'binds constant resolution' do
            subject
            node = node_traverser.query(type: :const).node
            expect(inferencer.tracer.constants(node)).to contain_exactly(
              have_attributes(path: "Integer"),
            )
          end
        end

        context 'a constant value is given' do
          let(:source) do
            <<~RUBY
            MAGIC_NUMBER.modulo(3)
            RUBY
          end

          before do
            read_source <<~RUBY
            # It's a magical number.
            MAGIC_NUMBER = 4
            RUBY
          end

          it 'infers the type of constant' do
            pending("For now, the inferred type becomes untyped")

            node = node_traverser.query(type: :send).node
            expect(inferencer.tracer.type(node.receiver)).to have_attributes(to_s: '4')
          end

          it 'does not failure on method inference' do
            expect { subject }.not_to raise_error
          end

          it 'binds constant resolution' do
            subject
            node = node_traverser.query(type: :send).node
            expect(inferencer.tracer.constants(node.receiver)).to contain_exactly(
              have_attributes(path: "MAGIC_NUMBER", document: "It's a magical number."),
            )
          end
        end
      end

      context 'with a nested constant' do
        let(:source) do
          <<~RUBY
          Hoge::Fuga
          RUBY
        end

        before do
          read_source <<~RUBY
          class Hoge
            class Fuga
            end
          end
          RUBY
        end

        it 'returns singleton class' do
          expect(subject).to have_attributes(to_s: 'singleton(::Hoge::Fuga)')
        end

        it 'binds constant resolution' do
          subject
          node = node_traverser.query(type: :const).node
          expect(inferencer.tracer.constants(node)).to contain_exactly(
            have_attributes(path: "Hoge::Fuga"),
          )
          expect(inferencer.tracer.constants(node.base)).to contain_exactly(
            have_attributes(path: "Hoge"),
          )
        end
      end

      context 'in a singleton class of constant value' do
        let(:source) do
          <<~RUBY
          class Hoge
            class << self
              Fuga
            end
          end
          RUBY
        end

        before do
          read_source <<~RUBY
          class Hoge; class Fuga; end; end
          RUBY
        end

        it 'binds the constants' do
          subject
          node = node_traverser.query(type: :sclass).node.body.query(type: :const)
          expect(inferencer.tracer.type(node)).to have_attributes(to_s: 'singleton(::Hoge::Fuga)')
          expect(inferencer.tracer.constants(node)).to contain_exactly(
            have_attributes(path: "Hoge::Fuga"),
          )
        end
      end
    end

    describe 'string literal' do
      describe 'without any interpolation' do
        let(:source) do
          <<~RUBY
          "string"
          RUBY
        end

        it 'returns a literal type' do
          expect(subject).to have_attributes(to_s: '"string"')
        end
      end

      describe 'with interpolations' do
        let(:source) do
          <<~RUBY
          "prefix\#{1}suffix"
          RUBY
        end

        it 'returns a string type' do
          expect(subject).to have_attributes(to_s: '::String')
        end

        it 'evaluate each interpolation' do
          subject
          node = node_traverser.query(type: :int).node
          expect(inferencer.tracer.type(node)).to have_attributes(to_s: '1')
        end
      end
    end

    describe 'rescue' do
      context 'with exception specification' do
        let(:source) do
          <<~RUBY
          begin
            1
          rescue Exception => e
            e
          end
          RUBY
        end

        it 'returns type of body' do
          expect(subject).to have_attributes(to_s: '1')
        end

        it 'returns type of variable' do
          subject
          node = node_traverser.query(type: :lvar).node
          expect(inferencer.tracer.type(node)).to have_attributes(to_s: "::Exception")
        end
      end

      context 'without exception specification' do
        let(:source) do
          <<~RUBY
          begin
            1
          rescue => e
            e
          end
          RUBY
        end

        it 'returns type of body' do
          expect(subject).to have_attributes(to_s: '1')
        end

        it 'returns type of variable' do
          subject
          node = node_traverser.query(type: :lvar).node
          expect(inferencer.tracer.type(node)).to have_attributes(to_s: "::StandardError")
        end
      end
    end

    describe 'rescue' do
      context 'with exception specification' do
        let(:source) do
          <<~RUBY
          begin
            1
          ensure
            i = 2
            i
          end
          RUBY
        end

        it 'returns type of body' do
          expect(subject).to have_attributes(to_s: '1')
        end

        it 'also evaluates ensure clause' do
          subject
          node = node_traverser.query(type: :lvar).node
          expect(inferencer.tracer.type(node)).to have_attributes(to_s: "2")
        end
      end
    end

    describe 'block calls' do
      context 'in block context of instance method' do
        let(:source) do
          <<~RUBY
          require 'set'
          RUBY
        end

        it 'can infer variable defined from outer context' do
          subject
          node = node_traverser.query(type: :send).node
          expect(inferencer.tracer.method_candidates(node)).to including(
            have_attributes(
              name: 'require',
              namespace_path: 'Kernel',
            )
          )
          path_node = node_traverser.query(type: :str).node
          expect(inferencer.tracer.require_paths(path_node)).to contain_exactly(be_end_with("set.rb"))
        end
      end
    end

    describe 'type annotation' do
      context 'when type annotation is prepended to variable assignment' do
        let(:source) do
          <<~RUBY
          # @type a [Integer]
          a = nil
          a.div(2)
          RUBY
        end

        it 'can infer variable defined from outer context' do
          subject
          node = node_traverser.query(type: :send).node
          expect(inferencer.tracer.type(node.receiver)).to have_attributes(to_s: "::Integer")
        end
      end
    end
  end
end
