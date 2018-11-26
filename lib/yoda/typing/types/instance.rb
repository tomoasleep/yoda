module Yoda
  module Typing
    module Types
      class Instance < Base
        attr_reader :klass, :meta_klass

        # @param klass [Store::Objects::NamespaceObject] class object for the instance.
        # @param meta_klass [Store::Objects::NamespaceObject, nil] meta class object for the instance.
        def initialize(klass:, meta_klass: nil)
          @klass = klass
          @meta_klass = meta_klass
        end

        def to_expression(resolver)
          Store::TypeExpressions::InstanceType.new(klass)
        end
      end
    end
  end
end
