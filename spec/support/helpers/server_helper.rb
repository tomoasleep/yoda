require "open3"
require "stringio"

module ServerHelper
  def capture_server(command:, fixture_path:)
    requests = []
    yield requests

    sio = StringIO.new
    requests.each { |request| lsp_write(sio, request) }

    Dir.chdir(fixture_path) do 
      output, error, status = Open3.capture3(command, stdin_data: sio.string)
      [jsonrpc_to_requests(output), error, status]
    end
  end

  def lsp_write(io, response)
    LanguageServer::Protocol::Transport::Io::Writer.new(io).write(response.to_hash)
  end

  def lsp_request(id:, method:, params:)
    lsp(:request_message, jsonrpc: "2.0", id: id, method: method, params: lsp("#{method}_params", **params))
  end

  def lsp(kind, **kwargs)
    LanguageServer::Protocol::Interface.const_get(camelize(kind)).new(**kwargs)
  end

  def camelize(str)
    str.to_s.sub(/^[a-z]*/) { |match| match.capitalize }.gsub(/(?:_)([a-z]*)/i) { $1.capitalize }
  end

  def jsonrpc_to_requests(str)
    sio = StringIO.new(str)
    requests = []
    LanguageServer::Protocol::Transport::Io::Reader.new(sio).read { |request| requests << request }
    requests
  end
end
