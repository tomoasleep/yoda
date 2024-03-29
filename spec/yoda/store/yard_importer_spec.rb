require 'spec_helper'

RSpec.describe Yoda::Store::YardImporter do
  include FileUriHelper
  include AddressHelper

  let(:importer) { described_class.new(id, source_path: "source_path") }
  let(:id) { 'test' }

  describe '#import' do
    subject { importer.import(YARD::Registry.all) }
    let(:path) { File.expand_path('etc/yard_importer/a.rb', fixture_root) }

    context "when the source is file" do
      before do
        YARD::Registry.clear
        YARD.parse(path)
      end

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
        expect(subject.patch.find('BaseModule::Nested::Object')).to be_a(Yoda::Store::Objects::ClassObject)
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
            *addresses(
              "BaseModule::Long",
              "BaseModule::Nested",
            ),
          ),
        )
        expect(subject.patch.find('BaseModule::Long')).to have_attributes(
          constant_addresses: contain_exactly(
            *addresses(
              "BaseModule::Long::Long2",
            ),
          ),
        )
        expect(subject.patch.find('BaseModule::Long::Long2')).to have_attributes(
          constant_addresses: contain_exactly(
            *addresses(
              "BaseModule::Long::Long2::Long3",
            ),
          ),
        )
        expect(subject.patch.find('BaseModule::Long::Long2::Long3')).to have_attributes(
          constant_addresses: be_empty,
          instance_method_addresses: contain_exactly(
            *addresses(
              "BaseModule::Long::Long2::Long3#test_method",
            ),
          ),
        )
        expect(subject.patch.find('BaseModule::Long::Long2::Long3%class')).to have_attributes(
          constant_addresses: be_empty,
          instance_method_addresses: contain_exactly(
            *addresses(
              "BaseModule::Long::Long2::Long3.test_singleton_method",
              "BaseModule::Long::Long2::Long3.test_singleton_class_method",
            ),
          ),
        )
        expect(subject.patch.find('BaseModule::Nested')).to have_attributes(
          constant_addresses: contain_exactly(
            *addresses(
              "BaseModule::Nested::Object",
              "BaseModule::Nested::Nested2",
              "BaseModule::Nested::ChildClass",
            ),
          ),
        )
      end

      it 'imports class object correctly' do
        expect(subject.patch.find('BaseModule::Nested::Nested2')).to have_attributes(
          superclass_path: Yoda::Model::Path.new('Object'),
          constant_addresses: be_empty,
          instance_method_addresses: contain_exactly(
            *addresses(
              "BaseModule::Nested::Nested2#test_method",
            ),
          ),
        )
        expect(subject.patch.find('BaseModule::Nested::Nested2%class')).to have_attributes(
          constant_addresses: be_empty,
          instance_method_addresses: contain_exactly(
            *addresses(
              "BaseModule::Nested::Nested2.test_singleton_method",
              "BaseModule::Nested::Nested2.test_singleton_class_method",
            ),
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

    context "when the source is stdin" do
      before do
        YARD::Registry.clear
        YARD.parse_string(File.read(path))
      end

      let(:source_path) { "source_path" }

      it 'imports module objects correctly' do
        objects = [
          subject.patch.find('BaseModule'),
          subject.patch.find('BaseModule::Long::Long2::Long3'),
          subject.patch.find('BaseModule::Long::Long2::Long3%class'),
          subject.patch.find('BaseModule::Long::Long2::Long3#test_method'),
          subject.patch.find('BaseModule::Long::Long2::Long3.test_singleton_method'),
          subject.patch.find('BaseModule::Long::Long2::Long3.test_singleton_class_method'),
          subject.patch.find('BaseModule::Nested::Object'),
          subject.patch.find('BaseModule::Nested::Nested2'),
          subject.patch.find('BaseModule::Nested::Nested2%class'),
          subject.patch.find('BaseModule::Nested::Nested2#test_method'),
          subject.patch.find('BaseModule::Nested::Nested2.test_singleton_method'),
          subject.patch.find('BaseModule::Nested::Nested2.test_singleton_class_method'),
          subject.patch.find('BaseModule::Nested::ChildClass'),
        ]
        expect(objects).to all(
          have_attributes(
            sources: contain_exactly(
              match([source_path, be_a(Integer), be_a(Integer)]),
            ),
          ),
        )
      end
    end
  end
end
