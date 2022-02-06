require 'delegate'

module Yoda
  module Model
    class Environment
      class ValueResolveContext
        # @return [ValueResolveContext]
        def self.empty
          new
        end

        # @return [RBS::Types::t, nil]
        attr_reader :self_type

        # @param self_type [RBS::Types::t, nil]
        def initialize(self_type: nil)
          @self_type = self_type
        end

        # @param type [RBS::Types::t]
        def wrap(type)
          WrappedType.new(type, context: self)
        end

        class WrappedType < SimpleDelegator
          # @return [ValueResolveContext]
          attr_reader :context

          # @param type [RBS::Types::t]
          # @param context [ValueResolveContext]
          def initialize(type, context:)
            @context = context
            super(type)
          end

          def act_as_type_wrapper?
            wrapped_type
          end

          # @return [WrappedType]
          def propage_context_to(another_type)
            context.wrap(another_type)
          end

          # @param type [RBS::Types::t]
          def wrapped_type
            __getobj__
          end

          # @param pp [PP]
          def pretty_print(pp)
            pp.object_group(self) do
              pp.breakable
              pp.text "type:"
              pp.pp wrapped_type
            end
          end
        end
      end
    end
  end
end
