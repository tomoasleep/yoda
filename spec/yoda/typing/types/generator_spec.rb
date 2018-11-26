require 'spec_helper'

RSpec.describe Yoda::Typing::Types::Generator do
  let(:registry) { Yoda::Store::Registry.new(adapter) }
  let(:generator) { described_class.new(registry) }
  let(:adapter) do
    Yoda::Store::Adapters::MemoryAdapter.new.tap do |adapter|
      objects.each { |object| adapter.put(object.address, object) }
    end
  end

  let(:objects) { [] }

  describe '#integer_type' do
    subject { generator.integer_type }

    context 'when integer type is not defined' do
      it { is_expected.to have_attributes(klass: have_attributes(path: 'Integer')) }
    end

    context 'when integer type is defined' do
      let(:objects) { [Yoda::Store::Objects::ClassObject.new(path: 'Integer')] }
      it { is_expected.to have_attributes(klass: have_attributes(path: 'Integer')) }
    end
  end
end
