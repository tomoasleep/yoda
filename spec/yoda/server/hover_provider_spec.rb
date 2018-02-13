require 'spec_helper'

RSpec.describe Yoda::Server::HoverProvider do
  LSP = ::LanguageServer::Protocol

  def file_uri(path)
    "file://#{File.expand_path(path, fixture_root)}"
  end

  let(:client_info) { described_class.new }
  after { client_info.project&.clean }

  let(:root_path) { fixture_root }
  let(:fixture_root) { File.expand_path('../../support/fixtures', __dir__) }
  let(:root_uri) { file_uri(root_path) }

  let(:client_info) { Yoda::Server::ClientInfo.new(root_uri) }
  let(:provider) { described_class.new(client_info) }

  describe '#request_hover' do
    before do
      client_info.setup
      client_info.file_store.load(uri)
    end
    subject { provider.request_hover(uri, position) }

    context 'request information in sample function' do
      let(:uri) { file_uri('lib/sample.rb') }
      let(:position) { { line: 7, character: 7 } }

      it 'returns completion for `self` variable' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(be_start_with('**String**'))
        expect(subject.range).to have_attributes(start: { line: 7, character: 6 }, end: { line: 7, character: 9 })
      end
    end

    context 'when the root namespace includes codes other than module definitions' do
      let(:uri) { file_uri('lib/sample3.rb') }
      let(:position) { { line: 13, character: 11} }

      it 'returns completion for `self` variable' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(be_start_with('**YodaFixture::Sample3.class**'))
        expect(subject.range).to have_attributes(start: { line: 13, character: 6 }, end: { line: 13, character: 13 })
      end
    end

    context 'request information at method send' do
      let(:uri) { file_uri('lib/sample3.rb') }
      let(:position) { { line: 17, character: 20} }

      it 'returns the description of the calling method' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(be_start_with('**YodaFixture::Sample3.class_method1(String str): any**'))
        expect(subject.range).to have_attributes(start: { line: 17, character: 6 }, end: { line: 17, character: 31 })
      end
    end

    describe 'Signatures provided by @!sig comment' do
      let(:uri) { file_uri('lib/hoge/sig.rb') }
      let(:position) { { line: 8, character: 15} }

      it 'returns the description of the calling method' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(be_start_with('**String#piyo: Integer**'))
        expect(subject.range).to have_attributes(start: { line: 8, character: 8 }, end: { line: 8, character: 16 })
      end
    end

    describe 'Signatures provided by overload tags' do
      let(:uri) { file_uri('lib/hoge/sig.rb') }
      let(:position) { { line: 8, character: 15} }

      it 'returns the description of the calling method' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(be_start_with('**String#piyo: Integer**'))
        expect(subject.range).to have_attributes(start: { line: 8, character: 8 }, end: { line: 8, character: 16 })
      end
    end

    describe 'Signatures provided by overload tags' do
      let(:uri) { file_uri('lib/hoge/sig.rb') }
      let(:position) { { line: 9, character: 15} }

      it 'returns the description of the calling method' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(be_start_with('**String#bytesize: Integer**'))
        expect(subject.range).to have_attributes(start: { line: 9, character: 8 }, end: { line: 9, character: 20 })
      end
    end

    context 'when the constant begin with cbase' do
      let(:uri) { file_uri('lib/namespace1/string.rb') }
      let(:position) { { line: 13, character: 13} }

      it 'returns the description of the calling method' do
        expect(subject).to be_a(LSP::Interface::Hover)
        expect(subject.contents).to contain_exactly(be_start_with('**String.class**'))
        expect(subject.range).to have_attributes(start: { line: 13, character: 8 }, end: { line: 13, character: 16 })
      end
    end
  end
end
