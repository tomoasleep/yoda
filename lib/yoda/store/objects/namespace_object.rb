module Yoda
  module Store
    module Objects
      # @abstract
      class NamespaceObject < Base
        # @return [Array<String>]
        attr_reader :instance_method_paths

        # @type (Array<String>) -> Array<String>
        attr_writer :instance_method_paths

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param instance_method_paths [Array<String>]
        # @param child_addresses [Array<String>]
        # @param instance_mixin_addresses [Array<String>]
        def initialize(path:, instance_method_paths: [], instance_mixin_addresses: [], child_addresses: [], **kwargs)
          super

          @instance_method_paths = instance_method_paths
          @instance_mixin_addresses = instance_mixin_addresses
          @child_addresses = child_addresses
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def to_h
          super.merge(instance_method_paths: instance_method_paths, instance_mixin_paths: instance_mixin_paths, child_addresses: child_addresses)
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            instance_method_paths: (instance_method_paths + another.instance_method_paths).uniq,
            instance_mixin_addresses: (instance_method_addresses + another.instance_method_addresses).uniq,
            child_addresses: (child_addresses + another.child_addresses).uniq,
          )
        end
      end
    end
  end
end
