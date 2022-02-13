require "open3"
require "stringio"

module ServerHelper
  def lsp_request(id:, method:, params:, kind: nil)
    params = begin
      if kind == Hash
        params
      else
        params_kind = kind ? "#{kind}_params" : "#{method}_params"
        lsp(params_kind, **params)
      end
    end

    lsp(:request_message, jsonrpc: "2.0", id: id, method: method, params: params)
  end

  def lsp(kind, **kwargs)
    constant = LanguageServer::Protocol::Interface.const_get(to_constant_name(kind))

    if kwargs.empty?
      # For Ruby 2.6
      constant.new
    else
      constant.new(**kwargs)
    end
  end

  def to_constant_name(str)
    str = str.to_s.split("/").last
    # camelize
    str.sub(/^[a-z]*/) { |match| match.capitalize }.gsub(/(?:_)([a-z]*)/i) { $1.capitalize }
  end

  class Client
    # @return [String]
    attr_reader :command

    # @return [IO, nil]
    attr_reader :stdin, :stdout, :stderr

    # @return [Array<Hash>]
    attr_reader :messages

    # @yield [client]
    # @yieldparam client [ServerHelper::Client]
    def self.run(command, **kwargs, &block)
      new(command, **kwargs).run(&block)
    end

    # @param command [String]
    # @param stream [Boolean]
    def initialize(command, stream: false)
      @command = command
      @stream = stream
      @messages = []
    end

    # @return [(Array<Hash>, String, Process::Status)]
    # @yield [client]
    # @yieldparam client [ServerHelper::Client]
    def run
      @messages = []

      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        @stdin = stdin
        @stdout = stdout
        @stderr = stderr

        error = ""
        stderr_th = Thread.new do
          while line = stderr.gets
            error << line
            STDERR.print line if @stream
          end
        end

        yield self

        stdin.close
        wait_thr.join
        stderr_th.join

        "Read all message" while read

        [messages, error, wait_thr.value]
      end
    end

    def read
      if buffer = stdout.gets("\r\n\r\n")
        content_length = buffer.match(/Content-Length: (\d+)/i)[1].to_i
        content = stdout.read(content_length) or raise
        message = JSON.parse(content, symbolize_names: true)

        @messages << message
        yield message if block_given?

        message
      else
        nil
      end
    end

    # @param message [#to_hash]
    def send(message)
      LanguageServer::Protocol::Transport::Io::Writer.new(stdin).write(message.to_hash)
    end

    # @param message [#to_hash]
    def <<(message)
      send(message)
    end
  end
end
