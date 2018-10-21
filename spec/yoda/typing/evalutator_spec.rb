require 'spec_helper'

RSpec.describe Yoda::Typing::Evaluator do
  include TypeHelper
  include AST::Sexp

  before do
    patch.register(root)
    instance_methods.each { |method| patch.register(method) }
    registry.add_patch(patch)
  end

  let(:registry) { Yoda::Store::Registry.new }
  let(:root) { Yoda::Store::Objects::ClassObject.new(path: 'Objects', instance_method_addresses: instance_methods.map(&:address)) }
  let(:patch) { Yoda::Store::Objects::Patch.new('test') }

  let(:instance_methods) { [] }

  let(:lexical_scope) { Yoda::Typing::LexicalScope.new(root, ['Object']) }
  let(:context) { Yoda::Typing::Context.new(registry: registry, caller_object: root, lexical_scope: lexical_scope) }
  let(:evaluator) { described_class.new(context) }

  shared_context 'define a method to root' do
    let(:instance_methods) do
      [
        Yoda::Store::Objects::MethodObject.new(
          path: 'Object#hoge',
          tag_list: [
            Yoda::Store::Objects::Tag.new(
              tag_name: 'return',
              yard_types: ['Hoge'],
            )
          ],
        )
      ]
    end
  end

  describe '#process' do
    subject { evaluator.process(ast) }

    context 'only an method send' do
      include_context 'define a method to root'

      let(:ast) do
        s(:send, nil, :hoge)
      end

      it 'returns the type of the method' do
        expect(subject).to eq(instance_type(Yoda::Model::ScopedPath.new(['Object'], 'Hoge')))
      end
    end

    context 'local variable assignment' do
      include_context 'define a method to root'

      let(:ast) do
        s(:begin,
          s(:lvasgn, :var, s(:send, nil, :hoge)),
          s(:lvar, :var),
        )
      end

      it "returns the assigned value's type" do
        expect(subject).to eq(instance_type(Yoda::Model::ScopedPath.new(['Object'], 'Hoge')))
      end
    end

    context 'local variable assignment' do
      include_context 'define a method to root'

      let(:ast) do
        s(:begin,
          s(:if,
            s(:send,
              s(:const, nil, :File), :exist?,
              s(:send, nil, :gemfile_lock_path)), nil,
            s(:return)),
          s(:lvasgn, :parser,
            s(:send,
              s(:const,
                s(:const, nil, :Bundler), :LockfileParser), :new,
              s(:send,
                s(:const, nil, :File), :read,
                s(:send, nil, :gemfile_lock_path)))),
          s(:block,
            s(:send,
              s(:send,
                s(:lvar, :parser), :specs), :each),
            s(:args,
              s(:arg, :gem)),
            s(:begin,
              s(:send,
                s(:const, nil, :STDERR), :puts,
                s(:dstr,
                  s(:str, "Building gem docs for "),
                  s(:begin,
                    s(:send,
                      s(:lvar, :gem), :name)),
                  s(:str, " "),
                  s(:begin,
                    s(:send,
                      s(:lvar, :gem), :version)))),
              s(:send,
                s(:const,
                  s(:const,
                    s(:const, nil, :YARD), :CLI), :Gems), :run,
                s(:send,
                  s(:lvar, :gem), :name),
                s(:send,
                  s(:lvar, :gem), :version)),
              s(:send,
                s(:const, nil, :STDERR), :puts,
                s(:dstr,
                  s(:str, "Done building gem docs for "),
                  s(:begin,
                    s(:send,
                      s(:lvar, :gem), :name)),
                  s(:str, " "),
                  s(:begin,
                    s(:send,
                      s(:lvar, :gem), :version)))))))
      end

      it "returns the assigned value's type" do
        # TODO
        expect(subject).to be_a(Yoda::Model::TypeExpressions::Base)
      end
    end

    context 'with empty body method' do
      include_context 'define a method to root'

      let(:ast) do
        s(:begin,
          s(:def, :handle_shutdown,
            s(:args,
              s(:arg, :_params)), nil),
          s(:nil),
        )
      end

      it 'does not fail' do
        expect(subject).to eq(Yoda::Model::TypeExpressions::ValueType.new('nil'))
      end
    end
  end
end
