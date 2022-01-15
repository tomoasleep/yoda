require 'forwardable'

module Yoda
  module Model
    module Values
      class InstanceValue < Base
        extend Forwardable

        # @return [Environment::AccessorInterface]
        attr_reader :class_accessor

        delegate [:select_constant_type, :select_constant_paths, :select_method] => :class_accessor_members

        # @param class_accessor [Environment::AccessorInterface]
        def initialize(class_accessor)
          @class_accessor = class_accessor
        end

        def referred_objects
          [class_accessor.class_object].compact
        end

        # @return [InstanceValue]
        def singleton_class_value
          InstanceValue.new(class_accessor.singleton_accessor)
        end

        # @return [InstanceValue, EmptyValue]
        def instance_value
          if class_accessor.instance_accessor
            InstanceValue.new(class_accessor.instance_accessor)
          else
            EmptyValue.new
          end
        end

        private

        # @return [Environment::NamespaceMembers]
        def class_accessor_members
          class_accessor.members
        end
      end
    end
  end
end
