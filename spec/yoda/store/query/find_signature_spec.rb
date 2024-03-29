require 'spec_helper'

RSpec.describe Yoda::Store::Query::FindSignature do
  before { project.setup }
  let(:project) { Yoda::Store::Project.for_path(root_path) }
  let(:registry) { project.registry }
  let(:root_path) { File.expand_path('../../../support/fixtures', __dir__) }

  describe '#select' do
    subject { described_class.new(registry).select(scope, name) }
    context 'for instance methods' do
      let(:scope) { Yoda::Store::Query::FindConstant.new(registry).find(scope_address) }

      context 'an instance method name is given' do
        let(:scope_address) { 'YodaFixture::Sample' }
        let(:name) { 'method1' }

        it 'returns the signature of the specified module' do
          expect(subject.first.type.to_s).to eq("(String str) -> any")
          expect(subject.first.namespace_path).to eq('YodaFixture::Sample')
          expect(subject.first.sep).to eq('#')
          expect(subject.first.name).to eq('method1')
        end
      end

      context 'an instance method name of super class is given' do
        let(:scope_address) { 'YodaFixture::ChildSample' }
        let(:name) { 'method1' }

        it 'returns the specified module' do
          expect(subject.first.type.to_s).to eq("any")
          expect(subject.first.namespace_path).to eq('YodaFixture::Sample3')
          expect(subject.first.sep).to eq('#')
          expect(subject.first.name).to eq('method1')
        end
      end
    end

    context 'for class methods' do
      let(:scope) { Yoda::Store::Query::FindMetaClass.new(registry).find(scope_address) }

      context 'a class method name is given' do
        let(:scope_address) { 'YodaFixture::Sample3' }
        let(:name) { 'class_method1' }

        it 'returns the specified module' do
          expect(subject.first.type.to_s).to eq("(String str) -> any")
          expect(subject.first.namespace_path).to eq('YodaFixture::Sample3')
          expect(subject.first.sep).to eq('.')
          expect(subject.first.name).to eq('class_method1')
        end
      end

      context 'an instance method name of super class is given' do
        let(:scope_address) { 'YodaFixture::ChildSample' }
        let(:name) { 'class_method1' }

        it 'returns the specified module' do
          expect(subject.first.type.to_s).to eq("(String str) -> any")
          expect(subject.first.namespace_path).to eq('YodaFixture::Sample3')
          expect(subject.first.sep).to eq('.')
          expect(subject.first.name).to eq('class_method1')
        end
      end
    end

    context 'for overloaded methods' do
      # TBW
    end

    context 'for constructor' do
      let(:scope) { Yoda::Store::Query::FindMetaClass.new(registry).find(scope_address) }

      context 'the given class does not overwrite new method' do
        let(:scope_address) { 'YodaFixture::Sample3' }
        let(:name) { 'new' }

        it 'returns the specified module' do
          expect(subject.first.type.to_s).to eq("YodaFixture::Sample3")
          expect(subject.first.namespace_path).to eq('YodaFixture::Sample3')
          expect(subject.first.sep).to eq('.')
          expect(subject.first.name).to eq('new')
        end
      end

      context 'the given class does not overwrite new method and initialize method' do
        let(:scope_address) { 'YodaFixture::ClassWithoutInitializer' }
        let(:name) { 'new' }

        it 'returns the specified module' do
          # Ensure that the class does not have initialize method
          expect(registry.get('YodaFixture::ClassWithoutInitializer#initialize')).to be_nil

          expect(subject.first.type.to_s).to eq("YodaFixture::ClassWithoutInitializer")
          expect(subject.first.namespace_path).to eq('YodaFixture::ClassWithoutInitializer')
          expect(subject.first.sep).to eq('.')
          expect(subject.first.name).to eq('new')
        end
      end
    end

    context 'when the given method has reference tags' do
      let(:scope) { Yoda::Store::Query::FindConstant.new(registry).find(scope_address) }

      context 'and the method has a forward argument' do
        let(:scope_address) { 'YodaFixture::ReferenceTagExamples' }
        let(:name) { 'method_with_forward_arg' }

        it 'returns the signature of the specified module' do
          expect(subject).to a_collection_including(
            have_attributes(
              namespace_path: 'YodaFixture::ReferenceTagExamples',
              sep: '#',
              name: 'method_with_forward_arg',
              parameters: have_attributes(raw_parameters: [['x', nil], ['y:', nil]]),
              type: have_attributes(to_s: '(String x, y: Integer) -> String'),
            ),
          )
        end
      end

      context 'and the method has same arguments' do
        let(:scope_address) { 'YodaFixture::ReferenceTagExamples' }
        let(:name) { 'method_with_same_args' }

        it 'returns the signature of the specified module' do
          expect(subject).to a_collection_including(
            have_attributes(
              namespace_path: 'YodaFixture::ReferenceTagExamples',
              sep: '#',
              name: 'method_with_same_args',
              parameters: have_attributes(raw_parameters: [['x', nil], ['y:', nil]]),
              type: have_attributes(to_s: '(String x, y: Integer) -> String'),
            ),
          )
        end
      end

      context 'and the method has a keyword rest argument' do
        let(:scope_address) { 'YodaFixture::ReferenceTagExamples' }
        let(:name) { 'method_with_kw_rest_arg' }

        it 'returns the signature of the specified module' do
          expect(subject.first).to (
            have_attributes(
              namespace_path: 'YodaFixture::ReferenceTagExamples',
              sep: '#',
              name: 'method_with_kw_rest_arg',
              parameters: have_attributes(raw_parameters: [['x', nil], ['**kwargs', nil]]),
              tags: a_collection_including(
                have_attributes(
                  tag_name: "param",
                  name: "x",
                  yard_types: ["String"],
                ),
                have_attributes(
                  tag_name: "option",
                  name: "kwargs",
                  option_key: "y",
                  yard_types: ["Integer"],
                ),
              ),
            )
          )
        end
      end
    end

    context 'when the given method has delegate tags' do
      let(:scope) { Yoda::Store::Query::FindMetaClass.new(registry).find(scope_address) }

      context 'and the method has a forward argument' do
        let(:scope_address) { 'YodaFixture::ReferenceTagExamples' }
        let(:name) { 'method1' }

        it 'returns the signature of the specified module' do
          expect(subject).to a_collection_including(
            have_attributes(
              namespace_path: 'YodaFixture::ReferenceTagExamples',
              sep: '.',
              name: 'method1',
              parameters: have_attributes(raw_parameters: [['x', nil], ['y:', nil]]),
              type: have_attributes(to_s: '(String x, y: Integer) -> String'),
            ),
          )
        end
      end
    end
  end
end
