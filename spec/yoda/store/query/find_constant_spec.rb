require 'spec_helper'

RSpec.describe Yoda::Store::Query::FindConstant do
  before { project.setup }
  let(:project) { Yoda::Store::Project.new(root_path) }
  let(:registry) { project.registry }
  let(:root_path) { File.expand_path('../../../support/fixtures', __dir__) }

  describe '#find' do
    subject { described_class.new(registry).find(name) }

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
  end

  describe '#select_with_prefix' do
    subject { described_class.new(registry).select_with_prefix(name) }

    context 'with module name string is given' do
      let(:name) { 'YodaFixture' }

      it 'returns array which includes only the specified module' do
        expect(subject).to all(be_a(Yoda::Store::Objects::ModuleObject))
        expect(subject).to include(have_attributes(path: name))
        expect(subject.length).to eq(1)
      end
    end
  end
end
