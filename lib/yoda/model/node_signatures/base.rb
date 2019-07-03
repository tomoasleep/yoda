module Yoda
  module Model
    module NodeSignatures
      # @abstract
      class Base
        # @return [Typing::NodeInfo]
        attr_reader :node_info

        # @param node_info [Typing::NodeInfo]
        def initialize(node_info)
          @node_info = node_info
        end

        # @return [Range]
        def node_range
          node_info.range
        end

        # @abstract
        # @return [Array<Descriptions::Base>]
        def descriptions
          fail NotImplementedError
        end

        # @return [Array<String>]
        def defined_files
          []
        end

        # @return [Descriptions::Base]
        def node_type_description
          Descriptions::NodeDescription.new(node_info.node, node_info.type_expression)
        end

        # @return [Array<Descriptions::Base>]
        def type_descriptions
          node_info.objects.map { |object| Descriptions::ValueDescription.new(object) }
        end
      end
    end
  end
end
