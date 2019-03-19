begin
  require "rubocop"
rescue LoadError
end

require "language_server-protocol"
require 'stringio'
require 'uri'
require 'json'


class BaseServer
  LSP = LanguageServer::Protocol

  attr_reader :writer, :reader, :mutex

  def initialize
    @writer = LSP::Transport::Stdio::Writer.new
    @reader = LSP::Transport::Stdio::Reader.new
    @mutex = Mutex.new
  end

  def write(**params)
    mutex.synchronize { writer.write(**params) }
  end

  def run
    reader.read do |request|
      begin
        method_name = "on_#{request[:method].gsub(/[A-Z]/) { |w| "_#{w.downcase}" }.gsub('/', '_')}"
        if respond_to?(method_name)
          result = public_send(method_name, request[:params] || {})
          write(id: request[:id], result: result) if result
        end
      rescue => e
        STDERR.puts e
        STDERR.puts e.backtrace
      end
    end
  end
end

class Server < BaseServer
  def on_initialize(**params)
    LSP::Interface::InitializeResult.new(
      capabilities: LSP::Interface::ServerCapabilities.new(
        text_document_sync: LSP::Interface::TextDocumentSyncOptions.new(
          change: LSP::Constant::TextDocumentSyncKind::FULL
        ),
      ),
    )
  end

  def on_text_document_did_save(**params)
    run_diagnostics(params[:textDocument][:uri])
    nil
  end

  def on_text_document_did_change(**params)
    run_diagnostics(params[:textDocument][:uri])
    nil
  end

  def on_text_document_did_open(**params)
    run_diagnostics(params[:textDocument][:uri])
    nil
  end

  private


  def run_diagnostics(uri)
    path = URI.parse(uri).path

    write(
      method: :"textDocument/publishDiagnostics",
      params: LSP::Interface::PublishDiagnosticsParams.new(
        uri: uri,
        diagnostics: run_cop(path),
      ),
    )
  end


  def run_cop(path)
    return [] unless defined? ::RuboCop
    args = []
    args += ["--config", '.rubocop.yml']
    args += ["--format", "json", path]
    o = nil
    begin
      $stdout = StringIO.new
      config_store = ::RuboCop::ConfigStore.new
      options, paths = ::RuboCop::Options.new.parse(args)
      config_store.options_config = options[:config] if options[:config]
      runner = ::RuboCop::Runner.new(options, config_store)
      runner.run(paths)
      o = $stdout.string
    ensure
      $stdout = STDOUT
    end
    return [] unless o
    JSON.
      parse(o)["files"].map { |v| v["offenses"] }.
      flatten.
      map do |v|
        line = v["location"]["line"].to_i - 1

        LSP::Interface::Diagnostic.new(
          range: LSP::Interface::Range.new(
            start: LSP::Interface::Position.new(line: line, character: 0),
            end: LSP::Interface::Position.new(line: line + 1, character: 0),
          ),
          message: v['message'],
          severity: convert_type(v['severity']),
        )
      end
  end

  def convert_type(type)
    case type
    when "refactor" then LSP::Constant::DiagnosticSeverity::WARNING
    when "convention" then LSP::Constant::DiagnosticSeverity::WARNING
    when "warning" then LSP::Constant::DiagnosticSeverity::WARNING
    when "error" then LSP::Constant::DiagnosticSeverity::ERROR
    when "fatal" then LSP::Constant::DiagnosticSeverity::ERROR
    end
  end
end

if __FILE__ == $0
  Server.new.run#.on_initialized
    #.on_text_document_did_open(textDocument: { uri: "file://#{File.absolute_path('spec/models/qiita_jobs/interactors/reveal_posting_spec.rb')}" })
end
