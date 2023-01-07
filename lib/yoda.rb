module Yoda
  require "yoda/version"
  require "yoda/logger"
  require "yoda/has_services"
  require "yoda/missing_delegatable"

  require "yoda/instrument"
  require "yoda/ast"
  require "yoda/cli"
  require "yoda/errors"
  require "yoda/id_mask"
  require "yoda/services"
  require "yoda/model"
  require "yoda/store"
  require "yoda/server"
  require "yoda/parsing"
  require "yoda/typing"
  require "yoda/yard_extensions"
  require "yoda/error_reporter"

  class << self
    # @return [Boolean]
    attr_accessor :inline_process

    def fork_process
      if inline_process?
        yield
      else
        Process.fork do
          require "tempfile"
          $stdout = Tempfile.new("yoda-stdout")

          Yoda::Instrument.clean
          yield
        end
      end
    end

    def inline_process?
      inline_process
    end
  end
end
