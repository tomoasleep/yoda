require 'spec_helper'

RSpec.describe Yoda::Store::Query::FindMetaClass do
  before { project.build_cache }
  let(:project) { Yoda::Store::Project.new(root_path) }
  let(:registry) { project.registry }
  let(:root_path) { File.expand_path('../../../support/fixtures', __dir__) }

  describe '#find' do
    subject { described_class.new(registry).find(name) }

    context 'when the name is Object' do
      let(:name) { 'Object' }

      it 'returns object class' do
        expect(subject).to be_a(Yoda::Store::Objects::MetaClassObject)
        expect(subject.path).to eq(name)
      end
    end

    context 'with module name string is given' do
      let(:name) { 'YodaFixture' }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::MetaClassObject)
        expect(subject.path).to eq('YodaFixture')
      end
    end

    context 'with module name path is given' do
      let(:name) { Yoda::Model::Path.new('YodaFixture') }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::MetaClassObject)
        expect(subject.path).to eq('YodaFixture')
      end
    end

    context 'with module name path with scopes is given' do
      let(:name) { Yoda::Model::ScopedPath.new(['Nested', 'Object'], 'Nested') }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::MetaClassObject)
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
end
