module Yoda
  module Typing
    module Types
      class Generator
        # @return [Registry]
        attr_reader :registry

        # @param registry [Registry]
        def initialize(registry)
          @registry = registry
        end

        # @return [Union]
        def boolean_type
          Union.new(true_type, false_type)
        end

        # @return [Instance]
        def true_type
          @true_type ||= instance_type_of('TrueClass')
        end

        # @return [Instance]
        def false_type
          @false_type ||= instance_type_of('FalseClass')
        end

        # @return [Instance]
        def nil_type
          @nil_type ||= instance_type_of('NilClass')
        end

        # @return [Instance]
        def string_type
          @string_type ||= instance_type_of('String')
        end

        # @return [Instance]
        def symbol_type
          @symbol_type ||= instance_type_of('Symbol')
        end

        # @return [Instance]
        def array_type
          @array_type ||= instance_type_of('Array')
        end

        # @return [Instance]
        def hash_type
          @hash_type ||= instance_type_of('Hash')
        end

        # @return [Instance]
        def range_type
          @range_type ||= instance_type_of('Range')
        end

        # @return [Instance]
        def regexp_type
          @regexp_type ||= instance_type_of('RegExp')
        end

        # @return [Instance]
        def proc_type
          @proc_type ||= instance_type_of('Proc')
        end

        # @return [Instance]
        def integer_type
          @integer_type ||= instance_type_of('Integer')
        end

        # @return [Instance]
        def float_type
          @float_type ||= instance_type_of('Float')
        end

        # @return [Instance]
        def numeric_type
          @numeric_type ||= instance_type_of('Numeric')
        end

        # @return [Any]
        def any_type
          Any.new
        end

        def class_class
          @class_class ||= find_or_build('Class')
        end

        def module_class
          @module_class ||= find_or_build('Module')
        end

        def object_class
          @object_class ||= find_or_build('Object')
        end

        # @return [Instance]
        def instance_type_of(path)
          Instance.new(klass: find_or_build(path))
        end

        # @param object [Store::Objects::Base]
        # @return [Instance]
        def constant_type_from(object)
          case object.kind
          when :class
            Instance.new(class_class, metaklass: object)
          when :module
            Instance.new(module_class, metaklass: object)
          else
            Instance.new(object_class, metaklass: object)
          end
        end

        # @return [Generator]
        def build_converter(**kwargs)
          Converter.new(self, **kwargs)
        end

        def find(path)
          Yoda::Store::Query::FindConstant.new(registry).find(path)
        end

        def find_meta_class(path)
          Yoda::Store::Query::FindMetaClass.new(registry).find(path)
        end

        def find_or_build(path)
          find(path) || Yoda::Store::Objects::ClassObject.new(path: path, superclass_path: 'Object')
        end

        def find_or_meta_singleton_class(path)
          find(path) || Yoda::Store::Objects::MetaClassObject.new(path: path)
        end
      end
    end
  end
end
