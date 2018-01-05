require 'spec_helper'

RSpec.describe Yoda::Typing::Context do
  include TypeHelper
  include AST::Sexp

  let(:registry) { Yoda::Store::Registry.instance }
  let(:root) { registry.at(:root) }

  let(:context) { Yoda::Typing::Context.new(registry, root, root) }

  describe '#find_instance_method_candidates' do
    subject { context.find_instance_method_candidates(code_objects, method_name) }
    let(:env) { Yoda::Typing::Environment.new }

    context 'a root object and its method name is given' do
      let(:method_name) { 'hoge' }
      let(:code_objects) { [root] }
      let!(:method_object) do
        YARD::CodeObjects::MethodObject.new(root, method_name) do |obj|
          obj.docstring = "@return [Hoge]"
        end
      end

      it 'returns the method of the name' do
        expect(subject).to contain_exactly(method_object)
      end
    end
  end
end
