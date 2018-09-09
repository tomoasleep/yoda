require 'spec_helper'

RSpec.describe Yoda::Server::Providers::Completion do
  include FileUriHelper

  let(:session) { Yoda::Server::Session.new(fixture_root_uri) }
  let(:writer) { instance_double('Yoda::Server::ConcurrentWriter').as_null_object }
  let(:notifier) { Yoda::Server::Notifier.new(writer) }
  let(:provider) { described_class.new(session: session, notifier: notifier) }

  describe '#provide' do
    before do
      session.setup
      session.file_store.load(uri)
    end
    let(:params) do
      {
        text_document: {
          uri: uri,
        },
        position: position,
      }
    end
    subject { provider.provide(params) }

    describe 'method completion' do
      context 'request information in sample function' do
        let(:uri) { file_uri('lib/sample.rb') }
        let(:position) { { line: 11, character: 12 } }
        let(:text_edit_range) { { start: { line: 11, character: 11 }, end: { line: 11, character: 18 } } }

        it 'returns infomation including appropriate labels' do
          expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
          expect(subject.is_incomplete).to be_falsy
          expect(subject.items).to include(
            have_attributes(label: 'method1(String str): any'),
            have_attributes(label: 'method2: any'),
            have_attributes(label: 'method3: any'),
          )
        end

        it 'returns infomation of `str` variable' do
          expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
          expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
          expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
          expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
          expect(subject.is_incomplete).to be_falsy
          expect(subject.items).to contain_exactly(
            have_attributes(
              detail: 'YodaFixture::Sample2.new: Sample2',
              text_edit: have_attributes(new_text: 'new', range: have_attributes(text_edit_range)),
            ),
          )
        end
      end
    end

    describe 'const completion' do
      let(:uri) { file_uri('lib/const_completion_fixture.rb') }

      context 'when the cursor is in an instance method' do
        context 'and the cursor is on a constant name' do
          context 'and the const node is single constant without cbase' do
            let(:position) { { line: 9, character: 15 } }
            let(:text_edit_range) { { start: { line: 9, character: 6 }, end: { line: 9, character: 28 } } }

            it 'returns infomation including appropriate labels' do
              expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to include(
                have_attributes(label: 'ConstCompletionFixture', text_edit: have_attributes(range: have_attributes(text_edit_range))),
              )
            end
          end

          context 'and the const node is single constant with cbase which does not exist' do
            let(:position) { { line: 10, character: 15 } }

            it 'returns empty candidates' do
              expect(subject.items).to be_empty
            end
          end

          context 'and the const node is single constant with cbase' do
            let(:position) { { line: 11, character: 15 } }
            let(:text_edit_range) { { start: { line: 11, character: 8 }, end: { line: 11, character: 19 } } }

            it 'returns infomation including appropriate labels' do
              expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to include(
                have_attributes(label: 'YodaFixture', text_edit: have_attributes(range: have_attributes(text_edit_range))),
              )
            end
          end

          context 'and the const node is single constant with cbase' do
            let(:position) { { line: 12, character: 30 } }
            let(:text_edit_range) { { start: { line: 12, character: 19 }, end: { line: 12, character: 41 } } }

            it 'returns infomation including appropriate labels' do
              expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to include(
                have_attributes(label: 'ConstCompletionFixture', text_edit: have_attributes(range: have_attributes(text_edit_range))),
              )
            end
          end

          context 'and there are constants with the common prefix of the const name but in different namespace' do
            let(:position) { { line: 13, character: 23 } }
            let(:text_edit_range) { { start: { line: 13, character: 19 }, end: { line: 13, character: 34 } } }

            it 'returns candidates of constants without ones in different namespace' do
              expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to contain_exactly(
                have_attributes(label: 'YodaInnerModule', text_edit: have_attributes(range: have_attributes(text_edit_range))),
              )
            end
          end
        end

        context 'and the cursor is after cbase' do
          let(:position) { { line: 11, character: 8 } }
          let(:text_edit_range) { { start: { line: 11, character: 6 }, end: { line: 11, character: 8 } } }

          it 'returns candidates under Object' do
            expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
            expect(subject.is_incomplete).to be_falsy
            expect(subject.items).to include(
              have_attributes(label: 'YodaFixture', text_edit: have_attributes(range: have_attributes(text_edit_range))),
            )
          end
        end

        context 'and the cursor is after double colons' do
          context 'and the const node is single constant without cbase' do
            let(:position) { { line: 12, character: 19 } }
            let(:text_edit_range) { { start: { line: 12, character: 17 }, end: { line: 12, character: 19 } } }

            it 'returns candidates under YodaFixture' do
              expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to include(
                have_attributes(label: 'ConstCompletionFixture', text_edit: have_attributes(range: have_attributes(text_edit_range))),
              )
              expect(subject.items).not_to include(have_attributes(label: 'YodaFixture'))
            end
          end
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
            expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
            expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
            expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
              expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
              expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
              expect(subject.is_incomplete).to be_falsy
              expect(subject.items).to include(
                have_attributes(text_edit: have_attributes(new_text: "String", range: have_attributes(text_edit_range))),
                have_attributes(text_edit: have_attributes(new_text: "Sample", range: have_attributes(text_edit_range))),
              )
            end
          end
        end

        context 'request after @type of a sample function' do
          let(:uri) { file_uri('lib/hoge/type_tag.rb') }
          let(:position) { { line: 3, character: 14 } }
          let(:text_edit_range) { { start: { line: 3, character: 14 }, end: { line: 3, character: 14 } } }

          it 'returns type candidates' do
            expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
            expect(subject.is_incomplete).to be_falsy
            expect(subject.items).to include(
              have_attributes(text_edit: have_attributes(new_text: "String", range: have_attributes(text_edit_range))),
              have_attributes(text_edit: have_attributes(new_text: "TypeTag", range: have_attributes(text_edit_range))),
            )
          end
        end

        context 'request on type content of @type' do
          let(:uri) { file_uri('lib/hoge/type_tag.rb') }
          let(:position) { { line: 3, character: 15 } }
          let(:text_edit_range) { { start: { line: 3, character: 14 }, end: { line: 3, character: 15 } } }

          it 'returns type candidates' do
            expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
            expect(subject.is_incomplete).to be_falsy
            expect(subject.items).to include(
              have_attributes(text_edit: have_attributes(new_text: "String", range: have_attributes(text_edit_range))),
              have_attributes(text_edit: have_attributes(new_text: "Sample", range: have_attributes(text_edit_range))),
            )
          end
        end

        context 'request on type content of @type and after "<"' do
          let(:uri) { file_uri('lib/hoge/type_tag.rb') }
          let(:position) { { line: 6, character: 20 } }
          let(:text_edit_range) { { start: { line: 6, character: 20 }, end: { line: 6, character: 20 } } }

          it 'returns type candidates' do
            expect(subject).to be_a(LanguageServer::Protocol::Interface::CompletionList)
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
