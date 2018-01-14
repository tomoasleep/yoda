require 'spec_helper'

RSpec.describe Yoda::Typing::Evaluator do
  include TypeHelper
  include AST::Sexp

  let(:registry) { Yoda::Store::Registry.instance }
  let(:root) { registry.at(:root) }
  let(:root_value) { Yoda::Store::Values::InstanceValue.new(registry, root) }

  let(:context) { Yoda::Typing::Context.new(registry, root_value) }
  let(:evaluator) { described_class.new(context) }

  shared_context 'define a method to root' do
    let(:method_name) { 'hoge' }
    let!(:method_object) do
      YARD::CodeObjects::MethodObject.new(root, method_name) do |obj|
        obj.docstring = "@return [Hoge]"
      end
    end
  end

  describe '#process' do
    subject { evaluator.process(ast, env) }
    let(:env) { Yoda::Typing::Environment.new }

    context 'only an method send' do
      include_context 'define a method to root'

      let(:ast) do
        s(:send, nil, method_name.to_sym)
      end

      it 'returns the type of the method' do
        expect(subject.first).to eq(instance_type(Yoda::Store::Path.new(root, 'Hoge')))
      end
    end

    context 'local variable assignment' do
      include_context 'define a method to root'

      let(:ast) do
        s(:begin,
          s(:lvasgn, :var, s(:send, nil, method_name.to_sym)),
          s(:lvar, :var),
        )
      end

      it "returns the assigned value's type" do
        expect(subject.first).to eq(instance_type(Yoda::Store::Path.new(root, 'Hoge')))
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
        expect(subject.first).to be_a(Yoda::Store::Types::Base)
      end
    end
  end
end
