module Yoda
  module Model
    module NodeSignatures
      class Const < Base
        def descriptions
          [node_type_description, *type_descriptions]
        end

        def defined_files
          node_info.objects.map { |value| value.primary_source || value.sources.first }.compact
        end
      end
    end
  end
end
