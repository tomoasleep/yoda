module Yoda
  module Model
    module FunctionSignatures
      # @abstract
      class Base
        # @abstract
        # @return [TypeExpressions::FunctionType]
        def type
          fail NotImplementedError
        end

        # @abstract
        # @param env [Environment]
        # @return [RBS::MethodType]
        def rbs_type(env)
          fail NotImplementedError
        end

        # @abstract
        # @return [Symbol]
        def visibility
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def name
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def namespace_path
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def document
          fail NotImplementedError
        end

        # @abstract
        # @return [ParameterList]
        def parameters
          fail NotImplementedError
        end

        # @abstract
        # @return [Array<(String, Integer, Integer)>]
        def sources
          fail NotImplementedError
        end

        # @return [String]
        def to_s
          formatter.to_s
        end

        # @abstract
        # @param param [String]
        # @return [TypeExpressions::Base, nil]
        def parameter_type_of(param)
          fail NotImplementedError
        end

        # @param env [Environment]
        # @return [Wrapper]
        def wrap(env)
          Wrapper.new(environment: env, signature: self)
        end

        private

        # @return [Formatter]
        def formatter
          @formatter ||= Formatter.new(self)
        end
      end
    end
  end
end
