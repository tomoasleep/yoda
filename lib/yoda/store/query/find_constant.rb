module Yoda
  module Store
    module Query
      class FindConstant < Base
        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Objects::Base, nil]
        def find(path)
          lexical_scope_paths = lexical_scopes_of(path)
          base_path = base_path_of(path)

          lexical_scope_paths.each do |path|
            scope = registry.find(path.to_s) || next
            obj = resolve_from_scope(scope, base_path)
            return obj if obj
          end

          if lexical_scope_paths.first && current_scope = registry.find(lexical_scope_paths.first) && current_scope.is_a?(Objects::NamespaceObject)
            find_from_ancestors(current_scope, base_path)
          else
            nil
          end
        end

        private

        # @param scope [Objects::NamespaceObject]
        # @param path [Path]
        # @return [Objects::Base, nil]
        def find_from_ancestors(scope, path)
          Associators::AssociateAncestors.new(registry).associate(scope)
          scope.ancestors.each do |ancestor|
            obj_path = Path.new(ancestor.path).concat(path)
            obj = registry.find(obj_path.to_s)
            return obj if obj
          end
        end

        # @param scope [Objects::Base]
        # @param path [Path]
        # @return [Objects::Base, nil]
        def resolve_from_scope(scope, path)
          obj_path = Path.new(current_scope.path).concat(path)
          registry.find(obj_path.to_s)
        end

        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Array<String>]
        def lexical_scopes_of(path)
          case path
          when Model::Path
            ['Object']
          when Model::ScopedPath
            path.scopes.map { |scope| scope.to_s.gsub(/\A::/, '') }
          else
            ['Object']
          end
        end

        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Model::Path]
        def base_path_of(path)
          case path
          when Model::Path
            path
          when Model::ScopedPath
            path.path
          else
            Model::Path.new(path.gsub(/\A::/, ''))
          end
        end
      end
    end
  end
end
