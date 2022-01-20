module Yoda
  module Model
    module NodeSignatures
      class Const < Base
        def descriptions
          [node_type_description, *constant_descriptions]
        end

        def defined_files
          node_info.objects.map { |value| PrimarySourceInferencer.new.infer_for_object(value) }.compact
        end

        # @return [Array<Descriptions::Base>]
        def constant_descriptions
          node_info.constants.map { |object| Descriptions::ValueDescription.new(object) }
        end
      end
    end
  end
end
