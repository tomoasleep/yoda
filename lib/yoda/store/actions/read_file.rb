module Yoda
  module Store
    module Actions
      class ReadFile
        # @return [Registry]
        attr_reader :registry

        # @return [String]
        attr_reader :file

        # @return [String, nil]
        attr_reader :content

        # @param registry [Registry]
        # @param file [String]
        # @return [void]
        def self.run(registry, file, content: nil, root_path: nil)
          self.new(registry, file, content: content, root_path: root_path).run
        end

        # @param file [String]
        # @return [String]
        def self.patch_id_for_file(file)
          YardImporter.patch_id_for_file(file)
        end

        # @param registry [Registry]
        # @param file [String]
        # @param content [String, nil]
        def initialize(registry, file, content: nil, root_path: nil)
          @registry = registry
          @file = file
          @content = content
          @root_path = root_path
        end

        # @return [void]
        def run
          YARD::Registry.clear
          if content
            YARD.parse_string(content) if Yoda::Parsing.parse_with_comments(content)
          else
            YARD.parse([file])
          end
          patch = YardImporter.new(file, source_path: file).import(YARD::Registry.all + [YARD::Registry.root]).patch
          registry.local_store.add_file_patch(patch)
        end
      end
    end
  end
end
