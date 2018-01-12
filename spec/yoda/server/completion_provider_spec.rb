require 'spec_helper'

RSpec.describe Yoda::Server::CompletionProvider do
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

  describe '#complete' do
    before do
      client_info.setup
      client_info.file_store.load(uri)
    end
    subject { provider.complete(uri, position) }

    context 'request information in sample function' do
      let(:uri) { file_uri('lib/sample.rb') }
      let(:position) { { line: 11, character: 12 } }
      let(:text_edit_range) { { start: { line: 11, character: 11 }, end: { line: 11, character: 18 } } }

      it 'returns infomation of `str` variable' do
        expect(subject).to be_a(LSP::Interface::CompletionList)
        expect(subject.is_incomplete).to be_falsy
        expect(subject.items).to include(
          have_attributes(text_edit: have_attributes(new_text: "method1", range: have_attributes(text_edit_range))),
          have_attributes(text_edit: have_attributes(new_text: "method2", range: have_attributes(text_edit_range))),
          have_attributes(text_edit: have_attributes(new_text: "method3", range: have_attributes(text_edit_range))),
        )
      end
    end

    context 'request information on the dot of a send node' do
      let(:uri) { file_uri('lib/sample.rb') }
      let(:position) { { line: 11, character: 11 } }
      let(:text_edit_range) { { start: { line: 11, character: 11 }, end: { line: 11, character: 11 } } }

      it 'returns infomation of `str` variable' do
        expect(subject).to be_a(LSP::Interface::CompletionList)
        expect(subject.is_incomplete).to be_falsy
        expect(subject.items).to include(
          have_attributes(text_edit: have_attributes(new_text: "method1", range: have_attributes(text_edit_range))),
          have_attributes(text_edit: have_attributes(new_text: "method2", range: have_attributes(text_edit_range))),
          have_attributes(text_edit: have_attributes(new_text: "method3", range: have_attributes(text_edit_range))),
        )
      end
    end
  end
end
