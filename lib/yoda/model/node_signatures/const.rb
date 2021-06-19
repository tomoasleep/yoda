module Yoda
  module Model
    module NodeSignatures
      class Const < Base
        def descriptions
          [node_type_description, *constant_descriptions]
        end

        def defined_files
          node_info.objects.map { |value| value.primary_source || value.sources.first }.compact
        end

        # @return [Array<Descriptions::Base>]
        def constant_descriptions
          node_info.constants.map { |object| Descriptions::ValueDescription.new(object) }
        end
      end
    end
  end
end
