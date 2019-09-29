module Yoda
  require "yoda/version"
  require "yoda/logger"
  require "yoda/has_services"
  require "yoda/missing_delegatable"

  require "yoda/instrument"
  require "yoda/ast"
  require "yoda/cli"
  require "yoda/errors"
  require "yoda/services"
  require "yoda/model"
  require "yoda/store"
  require "yoda/server"
  require "yoda/parsing"
  require "yoda/typing"
  require "yoda/yard_extensions"
end

YARD::Logger.instance.io = Yoda::Logger.instance.pipeline(tag: 'YARD')
