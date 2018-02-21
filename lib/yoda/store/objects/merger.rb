module Yoda
  module Store
    module Objects
      class Merger
        # @return [Array<Base>]
        attr_reader :instances

        # @param instances [Array<Base>]
        def initialize(instances)
          @instances = instances
        end

        # @return [Base]
        def merged_instance
          class_to_generate.new(attributes.select { |k, v| class_to_generate.attr_names.include?(k) }.to_h)
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
          @attributes ||= instances.map { |i| default_attributes.merge(i.to_h) }.reduce { |a, b| merge_attributes(a, b) }
        end

        # @param one [Hash{ Symbol => Object }]
        # @param another [Hash{ Symbol => Object }]
        def merge_attributes(one, another)
          {
            path: one[:path] || another[:path],
            document: one[:document] + (one[:document].empty? || another[:document].empty? ? '' : "\n") + another[:document],
            tag_list: one[:tag_list] + another[:tag_list],
            sources: one[:sources] + another[:sources],
            primary_source: one[:primary_source] || another[:primary_source],
            instance_method_addresses: one[:instance_method_addresses] + another[:instance_method_addresses],
            mixin_addresses: one[:mixin_addresses] + another[:mixin_addresses],
            constant_addresses: one[:constant_addresses] + another[:constant_addresses],
            visibility: one[:visibility] || another[:visibility],
            parameters: one[:parameters].empty? ? another[:parameters] : one[:parameters], 
            overloads: one[:overloads] + another[:overloads],
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
      end
    end
  end
end
