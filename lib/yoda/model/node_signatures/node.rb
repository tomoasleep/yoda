module Yoda
  module Model
    module NodeSignatures
      class Node < Base
        def descriptions
          if node_info.require_paths.empty?
            [node_type_description, *type_descriptions]
          else
            node_info.require_paths.map { |path| Descriptions::RequirePathDescription.new(path) }
          end
        end

        def defined_files
          node_info.require_paths.map { |path| [path, Parsing::Location.first_row, Parsing::Location.first_column] }
        end
      end
    end
  end
end
