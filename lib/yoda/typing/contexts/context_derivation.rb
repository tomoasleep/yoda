module Yoda
  module Typing
    module Contexts
      module ContextDerivation
        # @abstract
        # @return [Model::Environment]
        def environment
          fail NotImplementedError
        end

        # @abstract
        # @return [Types::Type]
        def receiver
          fail NotImplementedError
        end

        # @abstract
        # @return [Types::Type]
        def constant_ref
          fail NotImplementedError
        end

        # @param class_type [Types::Type]
        def derive_class_context(class_type:)
          NamespaceContext.new(
            parent: self,
            environment: environment,
            receiver: class_type,
            constant_ref: class_type,
          )
        end

        # @param receiver_type [Types::Type]
        # @param binds         [Hash{Symbol => Types::Type}, nil]
        def derive_method_context(receiver_type:, binds:)
          MethodContext.new(
            parent: self,
            environment: environment,
            receiver: receiver_type,
            constant_ref: constant_ref,
            binds: binds,
          )
        end

        # @param receiver_type [Types::Type]
        # @param binds         [Hash{Symbol => Types::Type}, nil]
        def derive_block_context(binds:, receiver_type: nil)
          BlockContext.new(
            parent: self,
            environment: environment,
            receiver: receiver_type || receiver,
            constant_ref: constant_ref,
            binds: binds,
          )
        end
      end
    end
  end
end
