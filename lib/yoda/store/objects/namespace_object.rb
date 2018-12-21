module Yoda
  module Store
    module Objects
      # @abstract
      class NamespaceObject < Base
        # @return [Array<String>]
        attr_reader :instance_method_addresses

        # @type Array<String>
        attr_reader :mixin_addresses

        # @type Array<String>
        attr_reader :constant_addresses

        # @return [Enumerable<NamespaceObject>]
        attr_accessor :ancestors

        # @return [Enumerable<MethodObject>]
        attr_accessor :methods

        # @return [Array<Symbol>]
        def self.attr_names
          super + %i(instance_method_addresses mixin_addresses constant_addresses)
        end

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param instance_method_paths [Array<String>]
        # @param constant_addresses [Array<String>]
        # @param mixin_addresses [Array<String>]
        def initialize(instance_method_addresses: [], mixin_addresses: [], constant_addresses: [], **kwargs)
          super(kwargs)
          @instance_method_addresses = instance_method_addresses
          @mixin_addresses = mixin_addresses
          @constant_addresses = constant_addresses
          @ancestors ||= []
        end

        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        def to_h
          super.merge(
            instance_method_addresses: instance_method_addresses,
            mixin_addresses: mixin_addresses,
            constant_addresses: constant_addresses,
          )
        end

        def namespace?
          true
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            instance_method_addresses: (instance_method_addresses + another.instance_method_addresses).uniq,
            mixin_addresses: (mixin_addresses + another.mixin_addresses).uniq,
            constant_addresses: (constant_addresses + another.constant_addresses).uniq,
          )
        end
      end
    end
  end
end
