require 'spec_helper'

RSpec.describe Yoda::Server::Providers::WorkspaceSymbol do
  include FileUriHelper

  let(:session) { Yoda::Server::Session.from_root_uri(fixture_root_uri) }
  let(:writer) { instance_double('Yoda::Server::ConcurrentWriter').as_null_object }
  let(:notifier) { Yoda::Server::Notifier.new(writer) }
  let(:provider) { described_class.new(session: session, notifier: notifier) }

  before do
    allow(notifier).to receive(:partial_result).and_wrap_original do |original_method, value:, **kwargs|
      partial_results.push(value)
      original_method.call(value: value, **kwargs)
    end
  end

  def partial_results
    @partial_results ||= []
  end

  describe '#provide' do
    before do
      session.setup
    end
    
    let(:params) do
      {
        query: query_string,
        work_done_token: "wdp",
        partial_result_token: "prt",
      }
    end

    subject { provider.provide(params) }

    context 'when query is empty' do
      let(:query_string) { "" }

      it 'returns infomation including appropriate labels' do
        expect(subject).to be_a(Array)
        
        expect(partial_results.flatten).to include(
          have_attributes(name: "initialize"),
          have_attributes(name: "method1"),
          have_attributes(name: "method6"),
        )
      end
    end
  end
end
