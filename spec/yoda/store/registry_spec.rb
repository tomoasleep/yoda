require 'spec_helper'

RSpec.describe Yoda::Store::Registry do 
  let(:registry) { Yoda::Store::Registry.new(adapter) }
  let(:adapter) { Yoda::Store::Adapters::MemoryAdapter.new }
  
  describe '#get' do
    let(:library_id) { :library }

    let(:patch) do
      Yoda::Store::Objects::Patch.new(
        library_id, [
          Yoda::Store::Objects::ClassObject.new(
            path: 'Hoge',
            instance_method_addresses: ['Object#to_s'],
          ),
          Yoda::Store::Objects::ClassObject.new(
            path: 'Fuga',
            instance_method_addresses: ['Object#id'],
          ),
          Yoda::Store::Objects::ClassObject.new(
            path: 'Piyo',
            instance_method_addresses: ['Object#to_s', 'Object#to_a'],
          ),
        ]
      )
    end

    before do
      registry.add_file_patch(patch)
    end

    it 'get the given objects' do
      expect(registry.get('Hoge')).to have_attributes(
        path: 'Hoge',
        instance_method_addresses: ['Object#to_s'],
      )
    end
  end
end
