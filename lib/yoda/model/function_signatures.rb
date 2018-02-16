module Yoda
  module Model
    module FunctionSignatures
      require 'yoda/model/function_signatures/base'
      require 'yoda/model/function_signatures/constructor'
      require 'yoda/model/function_signatures/overload'
      require 'yoda/model/function_signatures/method'
      require 'yoda/model/function_signatures/parameter_list'
      require 'yoda/model/function_signatures/type_builder'
      require 'yoda/model/function_signatures/formatter'

      # @param method_object [Store::Objects::MethodObject]
      # @return [Array<FunctionSignatures::Base>]
      def self.of_method(method_object)
        overload_tags = method_object.tags.select { |tag| tag.is_a?(Store::Objects::OverloadTag) }
        if overload_tags.empty?
          [Method.new(method_object)]
        else
          overload_tags.map { |overload_tag| Overload.new(method_object, overload_tag) }
        end
      end
    end
  end
end
