module Yoda
  module Store
    module Objects
      # @abstract
      class NamespaceObject < Base
        class Connected < Base::Connected
          delegate_to_object :instance_method_addresses, :mixin_addresses, :constant_addresses, :ancestors, :methods

          # @return [Enumerator<NamespaceObject::Connected>]
          def ancestors
            ancestor_tree.ancestors.map { |object| object.with_connection(**connection_options) }
          end

          # @return [Enumerator<NamespaceObject::Connected>]
          def mixins
            ancestor_tree.mixins.map { |object| object.with_connection(**connection_options) }
          end

          # @return [Query::MethodMemberSet]
          def method_members
            @method_members ||= Query::MethodMemberSet.new(registry: registry, object: object)
          end

          # @return [Query::ConstantMemberSet]
          def constant_members
            @constant_members ||= Query::ConstantMemberSet.new(registry: registry, object: object)
          end

          private

          def ancestor_tree
            @ancestor_tree ||= Query::AncestorTree.new(registry: registry, object: object)
          end
        end

        # @return [Array<Address>]
        attr_reader :instance_method_addresses

        # @return [Array<Address>]
        attr_reader :mixin_addresses

        # @return [Array<Address>]
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
        # @param instance_method_paths [Array<String, Address>]
        # @param constant_addresses [Array<String, Address>]
        # @param mixin_addresses [Array<String, Address>]
        def initialize(instance_method_addresses: [], mixin_addresses: [], constant_addresses: [], **kwargs)
          super(**kwargs)
          @instance_method_addresses = instance_method_addresses.map { |a| Address.of(a) }
          @mixin_addresses = mixin_addresses.map { |a| Address.of(a) }
          @constant_addresses = constant_addresses.map { |a| Address.of(a) }
          @ancestors ||= []
        end

        # @note Override of {Base#name}
        # @return [String]
        def name
          @name ||= path.match(MODULE_TAIL_PATTERN) { |md| md[1] || md[2] }
        end

        # @note Override of {Base#to_h}
        def to_h
          super.merge(
            instance_method_addresses: instance_method_addresses.map(&:to_s),
            mixin_addresses: mixin_addresses.map(&:to_s),
            constant_addresses: constant_addresses.map(&:to_s),
          )
        end

        # @note Override of {Base#namespace?}
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
