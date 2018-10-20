require 'spec_helper'

RSpec.describe Yoda::Store::YardImporter do
  include FileUriHelper

  let(:importer) { described_class.new(id) }
  let(:id) { 'test' }

  let(:loader) { described_class.new(registry: registry, gem_specs: gem_specs) }

  describe '#import' do
    before do
      YARD::Registry.clear
      YARD.parse(path)
    end

    subject { importer.import(YARD::Registry.all) }
    let(:path) { File.expand_path('etc/yard_importer/a.rb', fixture_root) }

    it 'imports code objects to its patch' do
      expect(subject.patch.find('BaseModule')).to be_a(Yoda::Store::Objects::ModuleObject)
      expect(subject.patch.find('BaseModule::Long')).to be_a(Yoda::Store::Objects::ModuleObject)
      expect(subject.patch.find('BaseModule::Long::Long2')).to be_a(Yoda::Store::Objects::ModuleObject)
      expect(subject.patch.find('BaseModule::Long::Long2::Long3')).to be_a(Yoda::Store::Objects::ModuleObject)
      expect(subject.patch.find('BaseModule::Long::Long2::Long3%class')).to be_a(Yoda::Store::Objects::MetaClassObject)
      expect(subject.patch.find('BaseModule::Long::Long2::Long3#test_method')).to be_a(Yoda::Store::Objects::MethodObject)
      expect(subject.patch.find('BaseModule::Long::Long2::Long3.test_singleton_method')).to be_a(Yoda::Store::Objects::MethodObject)
      expect(subject.patch.find('BaseModule::Long::Long2::Long3.test_singleton_class_method')).to be_a(Yoda::Store::Objects::MethodObject)
      expect(subject.patch.find('BaseModule::Nested')).to be_a(Yoda::Store::Objects::ModuleObject)
      expect(subject.patch.find('BaseModule::Nested::Nested2')).to be_a(Yoda::Store::Objects::ClassObject)
      expect(subject.patch.find('BaseModule::Nested::Nested2%class')).to be_a(Yoda::Store::Objects::MetaClassObject)
      expect(subject.patch.find('BaseModule::Nested::Nested2#test_method')).to be_a(Yoda::Store::Objects::MethodObject)
      expect(subject.patch.find('BaseModule::Nested::Nested2.test_singleton_method')).to be_a(Yoda::Store::Objects::MethodObject)
      expect(subject.patch.find('BaseModule::Nested::Nested2.test_singleton_class_method')).to be_a(Yoda::Store::Objects::MethodObject)
      expect(subject.patch.find('BaseModule::Nested::ChildClass')).to be_a(Yoda::Store::Objects::ClassObject)
    end

    it 'imports module objects correctly' do
      expect(subject.patch.find('BaseModule')).to have_attributes(
        constant_addresses: contain_exactly(
          "BaseModule::Long",
          "BaseModule::Nested",
        ),
      )
      expect(subject.patch.find('BaseModule::Long')).to have_attributes(
        constant_addresses: contain_exactly(
          "BaseModule::Long::Long2",
        ),
      )
      expect(subject.patch.find('BaseModule::Long::Long2')).to have_attributes(
        constant_addresses: contain_exactly(
          "BaseModule::Long::Long2::Long3",
        ),
      )
      expect(subject.patch.find('BaseModule::Long::Long2::Long3')).to have_attributes(
        constant_addresses: be_empty,
        instance_method_addresses: contain_exactly(
          "BaseModule::Long::Long2::Long3#test_method",
        ),
      )
      expect(subject.patch.find('BaseModule::Long::Long2::Long3%class')).to have_attributes(
        constant_addresses: be_empty,
        instance_method_addresses: contain_exactly(
          "BaseModule::Long::Long2::Long3.test_singleton_method",
          "BaseModule::Long::Long2::Long3.test_singleton_class_method",
        ),
      )
      expect(subject.patch.find('BaseModule::Nested')).to have_attributes(
        constant_addresses: contain_exactly(
          "BaseModule::Nested::Nested2",
          "BaseModule::Nested::ChildClass",
        ),
      )
    end

    it 'imports class object correctly' do
      expect(subject.patch.find('BaseModule::Nested::Nested2')).to have_attributes(
        superclass_path: Yoda::Model::Path.new('Object'),
        constant_addresses: be_empty,
        instance_method_addresses: contain_exactly(
          "BaseModule::Nested::Nested2#test_method",
        ),
      )
      expect(subject.patch.find('BaseModule::Nested::Nested2%class')).to have_attributes(
        constant_addresses: be_empty,
        instance_method_addresses: contain_exactly(
          "BaseModule::Nested::Nested2.test_singleton_method",
          "BaseModule::Nested::Nested2.test_singleton_class_method",
        ),
      )
      expect(subject.patch.find('BaseModule::Nested::ChildClass')).to have_attributes(
        superclass_path: Yoda::Model::Path.new('BaseModule::Nested::Nested2'),
        constant_addresses: be_empty,
        instance_method_addresses: be_empty,
      )
    end

    it 'imports method objects correctly' do
      expect(subject.patch.find('BaseModule::Long::Long2::Long3#test_method')).to have_attributes(
        visibility: :public,
        parameters: be_empty,
        overloads: be_empty,
        tag_list: contain_exactly(
          have_attributes(tag_name: 'return', yard_types: ['String'])
        ),
      )
      expect(subject.patch.find('BaseModule::Long::Long2::Long3.test_singleton_method')).to have_attributes(
        visibility: :public,
        parameters: be_empty,
        overloads: be_empty,
        tag_list: contain_exactly(
          have_attributes(tag_name: 'return', yard_types: ['Integer'])
        ),
      )
      expect(subject.patch.find('BaseModule::Long::Long2::Long3.test_singleton_class_method')).to have_attributes(
        visibility: :public,
        parameters: be_empty,
        overloads: be_empty,
        tag_list: contain_exactly(
          have_attributes(tag_name: 'return', yard_types: ['Integer'])
        ),
      )
      expect(subject.patch.find('BaseModule::Nested::Nested2#test_method')).to have_attributes(
        visibility: :public,
        parameters: be_empty,
        overloads: be_empty,
        tag_list: contain_exactly(
          have_attributes(tag_name: 'return', yard_types: ['String'])
        ),
      )
      expect(subject.patch.find('BaseModule::Nested::Nested2.test_singleton_method')).to have_attributes(
        visibility: :public,
        parameters: be_empty,
        overloads: be_empty,
        tag_list: contain_exactly(
          have_attributes(tag_name: 'return', yard_types: ['Integer'])
        ),
      )
      expect(subject.patch.find('BaseModule::Nested::Nested2.test_singleton_class_method')).to have_attributes(
        visibility: :public,
        parameters: be_empty,
        overloads: be_empty,
        tag_list: contain_exactly(
          have_attributes(tag_name: 'return', yard_types: ['Integer'])
        ),
      )
    end
  end
end
