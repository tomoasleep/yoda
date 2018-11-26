require 'spec_helper'

RSpec.describe Yoda::Store::Query::FindConstant do
  before { project.build_cache }
  let(:project) { Yoda::Store::Project.new(root_path) }
  let(:registry) { project.registry }
  let(:root_path) { File.expand_path('../../../support/fixtures', __dir__) }

  describe '#find' do
    subject { described_class.new(registry).find(name) }

    context 'when no constant is present for the name' do
      let(:name) { 'ConstantDoesNotExist' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the name is Object' do
      let(:name) { 'Object' }

      it 'returns object class' do
        expect(subject).to be_a(Yoda::Store::Objects::ClassObject)
        expect(subject.path).to eq(name)
      end
    end

    context 'with module name string is given' do
      let(:name) { 'YodaFixture' }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::ModuleObject)
        expect(subject.path).to eq(name)
      end
    end

    context 'with module name path is given' do
      let(:name) { Yoda::Model::Path.new('YodaFixture') }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::ModuleObject)
        expect(subject.path).to eq(name.to_s)
      end
    end

    context 'with module name path with scopes is given' do
      let(:name) { Yoda::Model::ScopedPath.new(['Nested', 'Object'], 'Nested') }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::ModuleObject)
        expect(subject.path).to eq('Nested::Nested')
      end
    end

    # @todo give a good description
    context 'with module name path with bad scopes is given' do
      let(:name) { Yoda::Model::ScopedPath.new(['Nested', 'Object'], 'Nested::Nested') }

      it 'returns nil' do
        expect(subject).not_to be
      end
    end

    context 'with cbase string is given' do
      let(:name) { '::' }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::ClassObject)
        expect(subject.path).to eq('Object')
      end
    end

    context 'with cbase string is given' do
      let(:name) { Yoda::Model::Path.new('::') }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::ClassObject)
        expect(subject.path).to eq('Object')
      end
    end

    context 'with path including assigned constant name is given' do
      let(:name) { Yoda::Model::Path.new('YF::Constant') }

      # @todo resolve constant assignment
      it 'does not fails' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#select_with_prefix' do
    subject { described_class.new(registry).select_with_prefix(name) }

    context 'when no constant is present for the name' do
      let(:name) { 'ConstantDoesNotExist' }

      it 'returns nil' do
        expect(subject).to be_empty
      end
    end

    context 'with module name string without separetors is given' do
      let(:name) { 'YodaFixture' }

      it 'returns array which includes only the specified module' do
        expect(subject).to all(be_a(Yoda::Store::Objects::ModuleObject))
        expect(subject).to include(have_attributes(path: 'YodaFixture'))
        expect(subject.length).to eq(1)
      end
    end

    context 'with module name which start with cbase is given' do
      let(:name) { '::YodaFixture' }

      it 'returns array which includes only the specified module' do
        expect(subject).to all(be_a(Yoda::Store::Objects::ModuleObject))
        expect(subject).to include(have_attributes(path: 'YodaFixture'))
        expect(subject.length).to eq(1)
      end
    end

    context 'with partial name string with a separator is given' do
      let(:name) { 'YodaFixture::Sam' }

      it 'returns array which includes only the specified module' do
        expect(subject).to include(
          have_attributes(path: 'YodaFixture::Sample').and(be_a(Yoda::Store::Objects::ClassObject)),
          have_attributes(path: 'YodaFixture::Sample2').and(be_a(Yoda::Store::Objects::ClassObject)),
          have_attributes(path: 'YodaFixture::Sample3').and(be_a(Yoda::Store::Objects::ClassObject)),
        )
        expect(subject.length).to eq(3)
      end
    end

    context 'with module name string whose suffix is separator is given' do
      let(:name) { 'YodaFixture::' }

      it 'returns constants in YodaFixture namespace' do
        expect(subject).to include(
          have_attributes(path: 'YodaFixture::Sample').and(be_a(Yoda::Store::Objects::ClassObject)),
          have_attributes(path: 'YodaFixture::Sample2').and(be_a(Yoda::Store::Objects::ClassObject)),
        )
      end
    end
  end
end
