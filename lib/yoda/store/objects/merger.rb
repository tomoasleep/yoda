require 'set'
require 'forwardable'

module Yoda
  module Store
    module Objects
      class Merger
        # @return [Array<Base>]
        attr_reader :instances

        # @param instances [Array<Base>]
        def initialize(instances)
          fail ArgumentError, 'instances must not be an empty array' if instances.empty?
          @instances = instances
        end

        # @return [Base]
        def merged_instance
          class_to_generate.new(**attributes.select { |k, v| class_to_generate.attr_names.include?(k) })
        end

        private

        # @return [Base.class]
        def class_to_generate
          @class_to_generate ||= begin
            if instances.any? { |el| el.is_a?(MetaClassObject) }
              MetaClassObject
            elsif instances.any? { |el| el.is_a?(ClassObject) }
              ClassObject
            elsif instances.any? { |el| el.is_a?(ModuleObject) }
              ModuleObject
            elsif instances.any? { |el| el.is_a?(MethodObject) }
              MethodObject
            else
              ValueObject
            end
          end
        end

        # @return [Hash{ Symbol => Object }]
        def attributes
          @attributes ||= normalize_attributes(instances.map { |i| default_attributes.merge(i.to_h) }.reduce { |a, b| merge_attributes(a, b) })
        end

        # @param one [Hash{ Symbol => Object }]
        # @param another [Hash{ Symbol => Object }]
        def merge_attributes(one, another)
          {
            path: one[:path] || another[:path],
            document: one[:document] + (one[:document].empty? || another[:document].empty? ? '' : "\n") + another[:document],
            tag_list: PendingArray.append(one[:tag_list], another[:tag_list]),
            sources: PendingSet.merge(one[:sources], another[:sources]),
            primary_source: one[:primary_source] || another[:primary_source],
            instance_method_addresses: PendingSet.merge(one[:instance_method_addresses], another[:instance_method_addresses]),
            mixin_addresses: PendingSet.merge(one[:mixin_addresses], another[:mixin_addresses]),
            constant_addresses: PendingSet.merge(one[:constant_addresses], another[:constant_addresses]),
            visibility: one[:visibility] || another[:visibility],
            parameters: one[:parameters].empty? ? another[:parameters] : one[:parameters],
            overloads: PendingArray.append(one[:overloads], another[:overloads]),
            superclass_path: select_superclass(one, another),
            value: one[:value] || another[:value],
          }
        end

        # @return [Hash{ Symbol => Object }]
        def default_attributes
          {
            path: nil,
            document: '',
            tag_list: [],
            sources: [],
            primary_source: nil,
            instance_method_addresses: [],
            mixin_addresses: [],
            constant_addresses: [],
            visibility: nil,
            parameters: [],
            overloads: [],
            superclass_path: nil,
            value: nil,
          }
        end

        # @param attrs [Hash{ Symbol => Object }]
        # @return [Hash{ Symbol => Object }]
        def normalize_attributes(attrs)
          {
            path: attrs[:path],
            document: attrs[:document],
            tag_list: attrs[:tag_list].to_a,
            sources: attrs[:sources].to_a,
            primary_source: attrs[:primary_source],
            instance_method_addresses: attrs[:instance_method_addresses].to_a,
            mixin_addresses: attrs[:mixin_addresses].to_a,
            constant_addresses: attrs[:constant_addresses].to_a,
            visibility: attrs[:visibility],
            parameters: attrs[:parameters].to_a,
            overloads: attrs[:overloads].to_a,
            superclass_path: attrs[:superclass_path],
            value: attrs[:value],
          }
        end

        # @param one [Hash{ Symbol => Object }]
        # @param another [Hash{ Symbol => Object }]
        # @return [ScopedPath]
        def select_superclass(one, another)
          if %w(Object Exception).include?(another[:path].to_s)
            one[:superclass_path] || another[:superclass_path]
          else
            another[:superclass_path] || one[:superclass_path]
          end
        end

        class PendingArray
          extend Forwardable

          # @param els1 [Array<Object>, PendingArray]
          # @param others [Array<Array<Object>, PendingArray>]
          def self.append(els, *others)
            if els.is_a?(PendingArray)
              others.reduce(els) { |array, item| array.append(item) }
            else
              append(PendingArray.new(els), *others)
            end
          end

          # @return [Array<Object>]
          attr_reader :array

          delegate %i(to_a each) => :array

          # @param els [Array<Object>]
          def initialize(els)
            @array = els.dup
          end

          # @param els [Array<Object>]
          def append(els)
            array.push(*els)
            self
          end
        end

        class PendingSet
          extend Forwardable

          # @param els1 [Array<Object>, PendingSet]
          # @param els2 [Array<Object>, PendingSet]
          def self.merge(els1, els2)
            if els1.is_a?(PendingSet)
              els1.merge(els2)
            else
              PendingSet.new(els1).merge(els2)
            end
          end

          # @return [Set<Object>]
          attr_reader :set

          delegate %i(to_a each) => :set

          # @param els [Array<Object>]
          def initialize(els)
            @set = Set.new(els)
          end

          # @param els [Array<Object>]
          def merge(els)
            set.merge(els)
            self
          end
        end
      end
    end
  end
end
