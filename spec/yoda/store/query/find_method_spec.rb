require 'spec_helper'

RSpec.describe Yoda::Store::Query::FindMethod do
  before { project.setup }
  let(:project) { Yoda::Store::Project.for_path(root_path) }
  let(:registry) { project.registry }
  let(:root_path) { File.expand_path('../../../support/fixtures', __dir__) }

  describe '#find' do
    subject { described_class.new(registry).find(scope, name) }
    context 'for instance methods' do
      let(:scope) { Yoda::Store::Query::FindConstant.new(registry).find(scope_address) }

      context 'an instance method name is given' do
        let(:scope_address) { 'YodaFixture::Sample' }
        let(:name) { 'method1' }

        it 'returns the specified module' do
          expect(subject).to be_a(Yoda::Store::Objects::MethodObject)
          expect(subject.path).to eq('YodaFixture::Sample#method1')
        end
      end

      context 'an instance method name of super class is given' do
        let(:scope_address) { 'YodaFixture::ChildSample' }
        let(:name) { 'method1' }

        it 'returns the specified module' do
          expect(subject).to be_a(Yoda::Store::Objects::MethodObject)
          expect(subject.path).to eq('YodaFixture::Sample3#method1')
        end
      end
    end

    context 'for class methods' do
      let(:scope) { Yoda::Store::Query::FindMetaClass.new(registry).find(scope_address) }

      context 'a class method name is given' do
        let(:scope_address) { 'YodaFixture::Sample3' }
        let(:name) { 'class_method1' }

        it 'returns the specified module' do
          expect(subject).to be_a(Yoda::Store::Objects::MethodObject)
          expect(subject.path).to eq('YodaFixture::Sample3.class_method1')
        end
      end

      context 'an instance method name of super class is given' do
        let(:scope_address) { 'YodaFixture::ChildSample' }
        let(:name) { 'class_method1' }

        it 'returns the specified module' do
          expect(subject).to be_a(Yoda::Store::Objects::MethodObject)
          expect(subject.path).to eq('YodaFixture::Sample3.class_method1')
        end
      end
    end
  end
end
