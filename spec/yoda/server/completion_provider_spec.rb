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

    describe 'method completion' do
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

      context 'request information on send node with empty receiver' do
        let(:uri) { file_uri('lib/sample2.rb') }
        let(:position) { { line: 26, character: 11 } }
        let(:text_edit_range) { { start: { line: 26, character: 6 }, end: { line: 26, character: 13 } } }

        it 'returns infomation of `str` variable' do
          expect(subject).to be_a(LSP::Interface::CompletionList)
          expect(subject.is_incomplete).to be_falsy
          expect(subject.items).to include(
            have_attributes(text_edit: have_attributes(new_text: "method1", range: have_attributes(text_edit_range))),
            have_attributes(text_edit: have_attributes(new_text: "method2", range: have_attributes(text_edit_range))),
            have_attributes(text_edit: have_attributes(new_text: "method3", range: have_attributes(text_edit_range))),
            have_attributes(text_edit: have_attributes(new_text: "method4", range: have_attributes(text_edit_range))),
            have_attributes(text_edit: have_attributes(new_text: "method5", range: have_attributes(text_edit_range))),
          )
        end
      end

      context 'request constructor information' do
        let(:uri) { file_uri('lib/sample2.rb') }
        let(:position) { { line: 31, character: 16 } }
        let(:text_edit_range) { { start: { line: 31, character: 14 }, end: { line: 31, character: 17 } } }

        it 'returns infomation of `str` variable' do
          expect(subject).to be_a(LSP::Interface::CompletionList)
          expect(subject.is_incomplete).to be_falsy
          expect(subject.items).to contain_exactly(
            have_attributes(
              detail: 'Sample2.new: Sample2',
              text_edit: have_attributes(new_text: 'new', range: have_attributes(text_edit_range)),
            ),
          )
        end
      end
    end

    describe 'comment completion' do
      describe 'tag completion' do
        context 'request on a sample function' do
          let(:uri) { file_uri('lib/sample.rb') }
          let(:position) { { line: 5, character: 8 } }
          let(:text_edit_range) { { start: { line: 5, character: 6 }, end: { line: 5, character: 8 } } }

          it 'returns @param and @private tags' do
            expect(subject).to be_a(LSP::Interface::CompletionList)
            expect(subject.is_incomplete).to be_falsy
            expect(subject.items).to include(
              have_attributes(text_edit: have_attributes(new_text: "@param", range: have_attributes(text_edit_range))),
              have_attributes(text_edit: have_attributes(new_text: "@private", range: have_attributes(text_edit_range))),
            )
          end
        end
      end

      describe 'type completion' do
        context 'request on @param of a sample function' do
          let(:uri) { file_uri('lib/sample.rb') }
          let(:position) { { line: 5, character: 19 } }
          let(:text_edit_range) { { start: { line: 5, character: 18 }, end: { line: 5, character: 19 } } }

          it 'returns type candidates' do
            expect(subject).to be_a(LSP::Interface::CompletionList)
            expect(subject.is_incomplete).to be_falsy
            expect(subject.items).to include(
              have_attributes(text_edit: have_attributes(new_text: "String", range: have_attributes(text_edit_range))),
              have_attributes(text_edit: have_attributes(new_text: "Sample", range: have_attributes(text_edit_range))),
            )
          end
        end

        context 'request on @return of a sample function' do
          let(:uri) { file_uri('lib/sample2.rb') }
          let(:position) { { line: 10, character: 29 } }
          let(:text_edit_range) { { start: { line: 10, character: 28 }, end: { line: 10, character: 29 } } }

          it 'returns type candidates' do
            expect(subject).to be_a(LSP::Interface::CompletionList)
            expect(subject.is_incomplete).to be_falsy
            expect(subject.items).to include(
              have_attributes(text_edit: have_attributes(new_text: "Sample", range: have_attributes(text_edit_range))),
              have_attributes(text_edit: have_attributes(new_text: "Sample2", range: have_attributes(text_edit_range))),
            )
          end
        end

        context 'in multiple namespaces and other statements' do
          context 'request on @param of a sample function' do
            let(:uri) { file_uri('lib/hoge/fuga.rb') }
            let(:position) { { line: 8, character: 21 } }
            let(:text_edit_range) { { start: { line: 8, character: 20 }, end: { line: 8, character: 21 } } }

            it 'returns type candidates' do
              expect(subject).to be_a(LSP::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to include(
                have_attributes(text_edit: have_attributes(new_text: "String", range: have_attributes(text_edit_range))),
                have_attributes(text_edit: have_attributes(new_text: "Sample", range: have_attributes(text_edit_range))),
              )
            end
          end

          context 'request on bracket in @param line of a sample function' do
            let(:uri) { file_uri('lib/hoge/fuga.rb') }
            let(:position) { { line: 8, character: 20 } }
            let(:text_edit_range) { { start: { line: 8, character: 20 }, end: { line: 8, character: 20 } } }

            it 'returns type candidates' do
              expect(subject).to be_a(LSP::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to include(
                have_attributes(text_edit: have_attributes(new_text: "String", range: have_attributes(text_edit_range))),
                have_attributes(text_edit: have_attributes(new_text: "Sample", range: have_attributes(text_edit_range))),
              )
            end
          end
        end
      end
    end
  end
end
