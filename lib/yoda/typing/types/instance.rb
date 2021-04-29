module Yoda
  module Typing
    module Types
      class Instance < Base
        attr_reader :klass

        # @param klass [Store::Objects::NamespaceObject] class object for the instance.
        def initialize(klass:)
          @klass = klass
        end

        def to_expression
          case klass.kind
          when :meta_class
            Model::TypeExpressions::ModuleType.new(klass.path)
          when :class, :module
            Model::TypeExpressions::InstanceType.new(klass.path)
          else
            fail NotImplementedError
          end
        end

        def to_type_string
          klass.path
        end
      end
    end
  end
end
