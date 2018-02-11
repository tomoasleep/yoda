require 'spec_helper'

RSpec.describe Yoda::Store::Query::FindMethod do
  before { Yoda::Store::Actions::ReadProjectFiles.new(registry, root_path).run }

  let(:registry) { Yoda::Store::Registry.new }
  let(:root_path) { File.expand_path('../../../support/fixtures', __dir__) }

  describe '#find' do
    subject { described_class.new(registry).find(scope, name) }
    let(:scope) { Yoda::Store::Query::FindConstant.new(registry).find(scope_address) }

    context 'with module name string is given' do
      let(:scope_address) { 'YodaFixture::Sample' }
      let(:name) { 'method1' }

      it 'returns the specified module' do
        expect(subject).to be_a(Yoda::Store::Objects::MethodObject)
        expect(subject.path).to eq('YodaFixture::Sample#method1')
      end
    end
  end
end
