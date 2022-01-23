require 'spec_helper'

RSpec.describe Yoda::Typing::Types::Generator do
  let(:environment) { Yoda::Model::Environment.build }
  let(:registry) { environment.registry }
  let(:generator) { described_class.new(environment: environment) }

  before do
    patch = Yoda::Store::Objects::Patch.new(:test).tap do |patch|
      objects.each { |object| patch.register(object) }
    end
    registry.local_store.add_file_patch(patch)
  end

  let(:objects) do
    [
      Yoda::Store::Objects::ClassObject.new(
        path: 'Object',
      ),
      Yoda::Store::Objects::ClassObject.new(
        path: 'Integer',
        superclass_path: 'Object',
      ),
    ]
  end

  describe '#integer_type' do
    subject { generator.integer_type }

    context 'when integer type is not defined' do
      it { is_expected.to have_attributes(to_s: "::Integer") }
    end

    context 'when integer type is defined' do
      let(:objects) { [Yoda::Store::Objects::ClassObject.new(path: 'Integer')] }
      it { is_expected.to have_attributes(to_s: "::Integer") }
    end
  end
end
