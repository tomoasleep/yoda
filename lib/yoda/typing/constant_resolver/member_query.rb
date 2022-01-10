require 'yoda/typing/constant_resolver/query'

module Yoda
  module Typing
    class ConstantResolver
      class MemberQuery < Query
        # @return [Query]
        attr_reader :parent

        # @return [Symbol]
        attr_reader :name

        # @return [NodeTracer, nil]
        attr_reader :tracer

        # @param parent [Query]
        # @param name [Symbol]
        # @param tracer [NodeTracer, nil]
        def initialize(parent:, name:, tracer: nil)
          @parent = parent
          @name = name
          @tracer = tracer
        end
      end
    end
  end
end
