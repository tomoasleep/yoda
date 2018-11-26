require 'spec_helper'

RSpec.describe Yoda::Typing::Inferencer do
  include AST::Sexp

  let(:registry) { Yoda::Store::Registry.new(adapter) }
  let(:receiver_type) { Yoda::Typing::Types::Instance.new(klass: registry.find('Object'))}
  let(:context) { Yoda::Typing::Inferencer::BlockContext.new(registry: registry, receiver: receiver_type) }

  let(:inferencer) { described_class.new(context) }

  let(:adapter) do
    Yoda::Store::Adapters::MemoryAdapter.new.tap do |adapter|
      objects.each { |object| adapter.put(object.address, object) }
    end
  end

  let(:objects) do
    [
      Yoda::Store::Objects::ClassObject.new(
        path: 'Object',
        constant_addresses: [
          'Integer',
          'Object',
        ],
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'Integer',
        superclass_path: 'Object',
        instance_method_addresses: ['Integer#+'],
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
    subject { inferencer.infer(ast) }

    context 'only an integer' do
      let(:source) do
        <<~EOS
        1
        EOS
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
        <<~EOS
        1 + 1
        EOS
      end

      it 'returns the type of the method' do
        expect(subject).to have_attributes(
          klass: have_attributes(
            path: 'Integer',
          )
        )
      end
    end
  end
end
