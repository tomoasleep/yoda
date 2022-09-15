require 'forwardable'

module Yoda
  module Model
    module FunctionSignatures
      # Wrap {FunctionSignatures::Base} and allow it access to environment.
      # TODO: Merge this with connected store
      class Wrapper
        extend Forwardable

        # @return [Environment]
        attr_reader :environment

        # @return [FunctionSignatures::Base]
        attr_reader :signature

        delegate [:name, :visibility, :sep, :namespace_path, :document, :tags, :sources, :parameters, :primary_source] => :signature

        # @param environment [Environment]
        # @param signature [FunctionSignatures::Base]
        def initialize(environment:, signature:)
          @environment = environment
          @signature = signature
        end

        # @param env [Environment]
        # @return [RBS::MethodType]
        def rbs_type
          signature.rbs_type(environment)
        end

        def to_s(include_namespace: false)
          if include_namespace
            "#{namespace_path}#{sep}#{name}#{rbs_type.to_s}"
          else
            "#{name}#{rbs_type.to_s}"
          end
        end

        def wrapper(env)
          Wrapper.new(environment: env, signature: signature)
        end
      end
    end
  end
end
