module Yoda
  module Store
    module Query
      class FindConstant < Base
        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Objects::Base, nil]
        def find(path)
          lexical_scope_paths = lexical_scopes_of(path)
          base_name, *constant_names = path_of(path).split
          # if path start with '::', base_name becomes ''.
          base_namespace_key = base_name == '' ? 'Object' : base_name
          base_namespace = select_base_namespace(base_namespace_key, lexical_scope_paths).first

          if constant_names.empty?
            # When the path does not contain separator (`::`)
            base_namespace
          else
            find_constant(constant_names.join('::'), base_namespace)
          end
        end

        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Array<Objects::Base>]
        def select_with_prefix(path)
          lexical_scope_paths = lexical_scopes_of(path)
          base_name, *constant_names, bottom_name = path_of(path).split

          if constant_names.empty? && !bottom_name
            # When the path does not contain separator (`::`)
            select_base_namespace(/\A#{Regexp.escape(base_name || '')}/, lexical_scope_paths).to_a.uniq
          else
            base_namespace = select_base_namespace(base_name, lexical_scope_paths).first
            scope = find_constant(constant_names.join('::'), base_namespace)
            return [] unless scope
            select_constants_from_ancestors(scope, /\A#{bottom_name}/).to_a
          end
        end

        private

        # Find namespaces which matches with the lexical scopes and the unnested constant name.
        #
        # @param base_name [String, Regexp] is an unnested constant name or a pattern of unnested constant name.
        # @param lexical_scope_paths [Array<String>]
        # @return [Enumerator<Objects::Base>]
        def select_base_namespace(base_name, lexical_scope_paths)
          Enumerator.new do |yielder|
            lexical_scope_paths.each do |path|
              scope = find_constant(path.to_s)
              next if !scope || !scope.is_a?(Objects::NamespaceObject)
              select_child_constants(scope, base_name).each do |obj|
                yielder << obj
              end
            end

            nearest_scope_path = lexical_scope_paths.first
            if nearest_scope_path && nearest_scope = find_constant(nearest_scope_path) && nearest_scope.is_a?(Objects::NamespaceObject)
              select_constants_from_ancestors(nearest_scope, base_name).each do |obj|
                yielder << obj
              end
            end
          end
        end

        # @param name [String, Model::Path]
        # @param namespace [Objects::Base, nil]
        # @return [Objects::Base, nil]
        def find_constant(name, namespace = nil)
          constant_names = path_of(name).split
          namespace = registry.get('Object') unless namespace
          constant_names.reduce(namespace) do |namespace, name|
            # @todo resolve its value if namespace is ValueObject
            if namespace && namespace.is_a?(Objects::NamespaceObject)
              select_constants_from_ancestors(namespace, name).first
            else
              return nil
            end
          end
        end

        # @param scope [Objects::NamespaceObject]
        # @param name [String, Regexp]
        # @return [Enumerator<Objects::Base>]
        def select_constants_from_ancestors(scope, name)
          Enumerator.new do |yielder|
            met = Set.new

            Associators::AssociateAncestors.new(registry).associate(scope).each do |ancestor|
              select_child_constants(ancestor, name).each do |obj|
                next if met.include?(obj.name)
                met.add(obj.name)
                yielder << obj
              end
            end
          end
        end

        # @param scope [Objects::Base]
        # @param name [String, Regexp]
        # @return [Enumerator<Objects::Base>]
        def select_child_constants(scope, name)
          Enumerator.new do |yielder|
            if scope.is_a?(Objects::NamespaceObject)
              scope.constant_addresses.select { |address| match_name?(Model::Path.new(address).basename, name) }.each do |address|
                obj = registry.get(address)
                yielder << obj if obj
              end
            end
          end
        end

        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Array<String>]
        def lexical_scopes_of(path)
          case path
          when Model::Path
            ['Object']
          when Model::ScopedPath
            if path.path.absolute?
              ['Object']
            else
              path.scopes.map { |scope| scope.to_s.gsub(/\A::/, '') }
            end
          else
            ['Object']
          end
        end

        # @param path [String, Model::Path, Model::ScopedPath]
        # @return [Model::Path]
        def path_of(path)
          case path
          when Model::Path
            path
          when Model::ScopedPath
            path.path
          when String
            Model::Path.new(path == '::' ? '::' : path.gsub(/\A::/, ''))
          else
            fail ArgumentError, path
          end
        end

        # @param name [String]
        # @param expected_name_or_pattern [String, Regexp]
        # @return [true, false]
        def match_name?(name, expected_name_or_pattern)
          if expected_name_or_pattern.is_a?(String)
            name == expected_name_or_pattern
          else
            name.match?(expected_name_or_pattern)
          end
        end
      end
    end
  end
end
