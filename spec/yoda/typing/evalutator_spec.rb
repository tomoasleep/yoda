require 'spec_helper'

RSpec.describe Yoda::Typing::Evaluator do
  include TypeHelper
  include AST::Sexp

  let(:registry) { Yoda::Store::Registry.instance }
  let(:root) { registry.at(:root) }

  let(:context) { Yoda::Typing::Context.new(registry, root, root) }
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
        expect(subject.first).to eq(constant_type(Yoda::Store::Path.new(root, 'Hoge')))
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
        expect(subject.first).to eq(constant_type(Yoda::Store::Path.new(root, 'Hoge')))
      end
    end
  end
end
