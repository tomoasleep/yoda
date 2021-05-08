module Yoda
  module Typing
    module Contexts
      require 'yoda/typing/contexts/base_context'
      require 'yoda/typing/contexts/block_context'
      require 'yoda/typing/contexts/method_context'
      require 'yoda/typing/contexts/namespace_block_context'
      require 'yoda/typing/contexts/namespace_context'

      # @return [NamespaceContext]
      def self.root_scope(environment:)
        generator = Types::Generator.new(environment: environment)

        object_type = generator.instance_type_at("::Object")
        object_class_type = generator.singleton_type_at("::Object")

        NamespaceContext.new(
          environment: environment,
          receiver: object_type,
          constant_ref: object_class_type,
        )
      end
    end
  end
end
