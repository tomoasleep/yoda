require 'spec_helper'

RSpec.describe Yoda::Store::Objects::PatchSet do
  let(:patch_set) do
    Yoda::Store::Objects::PatchSet.new.tap { |patch_set| patches.each { |patch| patch_set.register(patch) } }
  end

  describe '#find' do
    subject { patch_set.find(key) }

    describe 'instance method addresses' do
      let(:patches) do
        [
          Yoda::Store::Objects::Patch.new(
            'patch1',
            [
              Yoda::Store::Objects::ClassObject.new(
                path: 'Object',
                instance_method_addresses: ['Object#to_s'],
              ),
            ],
          ),
          Yoda::Store::Objects::Patch.new(
            'patch2',
            [
              Yoda::Store::Objects::ClassObject.new(
                path: 'Object',
                instance_method_addresses: ['Object#id'],
              ),
            ],
          ),
          Yoda::Store::Objects::Patch.new(
            'patch3',
            [
              Yoda::Store::Objects::ClassObject.new(
                path: 'Object',
                instance_method_addresses: ['Object#to_s', 'Object#to_a'],
              ),
            ],
          ),
        ]
      end
      let(:key) { 'Object' }

      it 'merges' do
        expect(subject).to be_a(Yoda::Store::Objects::ClassObject)
        expect(subject.to_h).to include(
          path: 'Object',
          instance_method_addresses: contain_exactly('Object#to_s', 'Object#id', 'Object#to_a'),
        )
      end
    end

    describe 'tag list' do
      let(:patches) do
        [
          Yoda::Store::Objects::Patch.new(
            'patch1',
            [
              Yoda::Store::Objects::ClassObject.new(
                path: 'Object',
                tag_list: [Yoda::Store::Objects::Tag.new(tag_name: 'private')],
              ),
            ],
          ),
          Yoda::Store::Objects::Patch.new(
            'patch2',
            [
              Yoda::Store::Objects::ClassObject.new(
                path: 'Object',
                tag_list: [Yoda::Store::Objects::Tag.new(tag_name: 'deprecated')],
              ),
            ],
          ),
          Yoda::Store::Objects::Patch.new(
            'patch3',
            [
              Yoda::Store::Objects::ClassObject.new(
                path: 'Object',
                tag_list: [Yoda::Store::Objects::Tag.new(tag_name: 'abstract')],
              ),
            ],
          ),
        ]
      end
      let(:key) { 'Object' }

      it 'merges' do
        expect(subject).to be_a(Yoda::Store::Objects::ClassObject)
        expect(subject.to_h).to include(
          path: 'Object',
          tag_list: contain_exactly(
            Yoda::Store::Objects::Tag.new(tag_name: 'private'),
            Yoda::Store::Objects::Tag.new(tag_name: 'deprecated'),
            Yoda::Store::Objects::Tag.new(tag_name: 'abstract'),
          ),
        )
      end
    end
  end
end
