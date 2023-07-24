module Yoda
  module Store
    module Objects
      # @abstract
      class NamespaceObject < Base
        class Connected < Base::Connected
          delegate_to_object :instance_method_addresses, :include_accesses, :prepend_accesses, :constant_addresses, :rbs_type_params_overloads, :ancestors, :methods

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

        # @return [Array<NamespaceAccess>]
        attr_reader :include_accesses

        # @return [Array<NamespaceAccess>]
        attr_reader :prepend_accesses

        # @return [Array<Address>]
        attr_reader :constant_addresses

        # @return [Enumerable<NamespaceObject>]
        attr_accessor :ancestors

        # @return [Enumerable<MethodObject>]
        attr_accessor :methods

        # @return [Array<Array<TypeParam>>]
        attr_accessor :rbs_type_params_overloads

        # @return [Array<Symbol>]
        def self.attr_names
          super + %i(instance_method_addresses include_accesses prepend_accesses constant_addresses)
        end

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param instance_method_paths [Array<String, Address>]
        # @param constant_addresses [Array<String, Address>]
        # @param include_accesses [Array<String, Address>]
        # @param rbs_type_params_overloads [Array<Array<TypeParam, Hash>>]
        def initialize(instance_method_addresses: [], include_accesses: [], prepend_accesses: [], constant_addresses: [], rbs_type_params_overloads: [], **kwargs)
          super(**kwargs)
          @instance_method_addresses = instance_method_addresses.map { |a| Address.of(a) }
          @include_accesses = include_accesses.map { |a| RbsTypes::NamespaceAccess.of(a) }
          @prepend_accesses = prepend_accesses.map { |a| RbsTypes::NamespaceAccess.of(a) }
          @constant_addresses = constant_addresses.map { |a| Address.of(a) }
          @rbs_type_params_overloads = rbs_type_params_overloads.map(&RbsTypes::TypeParam.method(:multiple_of))
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
            include_accesses: include_accesses.map(&:to_h),
            prepend_accesses: prepend_accesses.map(&:to_h),
            rbs_type_params_overloads: rbs_type_params_overloads.map { |overload| overload.map(&:to_h) },
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
            include_accesses: (include_accesses + another.include_accesses).uniq,
            prepend_accesses: (prepend_accesses + another.prepend_accesses).uniq,
            rbs_type_params_overloads: (rbs_type_params_overloads + another.rbs_type_params_overloads).uniq,
            constant_addresses: (constant_addresses + another.constant_addresses).uniq,
          )
        end
      end
    end
  end
end
