module Yoda
  module Parsing
    module Scopes
      require 'yoda/parsing/scopes/base'
      require 'yoda/parsing/scopes/root'
      require 'yoda/parsing/scopes/method_definition'
      require 'yoda/parsing/scopes/module_definition'
      require 'yoda/parsing/scopes/class_definition'
      require 'yoda/parsing/scopes/meta_method_definition'
      require 'yoda/parsing/scopes/meta_class_definition'

      require 'yoda/parsing/scopes/builder'
    end
  end
end
