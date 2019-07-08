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

        # @param object_class [Store::Objects::NamespaceObject]
        # @return [Instance]
        def object_type(object_class)
          Instance.new(klass: object_class)
        end

        # @param object_class [Store::Objects::NamespaceObject]
        # @return [Instance]
        def instance_type(object_class)
          instance_type_of(object_class.path)
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

        # @return [Instance]
        def singleton_type_of(path)
          Instance.new(klass: find_or_singleton_class(path))
        end

        # @param types [Array<Base>]
        # @return [Union]
        def union(*types)
          Union.new(*types)
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
          find(path) || Yoda::Store::Objects::ClassObject.new(path: normalize_path(path), superclass_path: 'Object')
        end

        def find_or_singleton_class(path)
          find_meta_class(path) || Yoda::Store::Objects::MetaClassObject.new(path: normalize_path(path))
        end

        private

        def normalize_path(path)
          case path
          when Model::ScopedPath
            path.paths.first.to_s
          when Model::Path
            path.to_s
          when String, Symbol
            path.to_s
          else
            fail TypeError, path
          end
        end
      end
    end
  end
end
