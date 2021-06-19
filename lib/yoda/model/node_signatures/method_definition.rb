module Yoda
  module Model
    module NodeSignatures
      class MethodDefinition < Base
        def descriptions
          [node_type_description, *function_descriptions]
        end

        def function_descriptions
          node_info.method_candidates.map { |function| Descriptions::FunctionDescription.new(function) }
        end

        # @return [Array<(String, Integer, Integer)>]
        def defined_files
          node_info.method_candidates.map { |function| function.primary_source }.compact
        end
      end
    end
  end
end
