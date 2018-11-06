module Yoda
  module Parsing
    module NodeObjects
      class ArgsNode

        # @param node [::AST::Node]
        attr_reader :node

        # @param node [::AST::Node]
        def initialize(node)
          fail ArgumentError, node unless node.is_a?(::AST::Node) && node.type == :args
          @node = node
        end

        # @return [Model::Parameters::Multiple]
        def parameter
          Model::Parameters::Multiple.new(
            parameters: parameter_nodes.map(&method(:parse_arg_node)),
            rest_parameter: rest_parameter_node && parse_single_arg_node(rest_parameter_node),
            post_parameters: post_parameter_nodes.map(&method(:parse_arg_node)),
            keyword_parameters: keyword_parameter_nodes.map { |arg_node| Model::Parameters::Named.new(arg_node.children.first) },
            keyword_rest_parameter: keyword_rest_parameter_node && parse_single_arg_node(keyword_rest_parameter_node),
            block_parameter: block_parameter_node && parse_single_arg_node(block_parameter_node),
          )
        end

        # @return [Array<::AST::Node>]
        def parameter_nodes
          @parameter_nodes ||= node.children.take_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
        end

        # @return [::AST::Node, nil]
        def rest_parameter_node
          @rest_parameter_node ||= node.children.find { |arg_node| arg_node.type == :restarg }
        end

        # @return [Array<::AST::Node>]
        def post_parameter_nodes
          @post_parameter_nodes ||= node.children.drop_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }.select { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
        end

        # @return [Array<::AST::Node>]
        def keyword_parameter_nodes
          @keyword_parameter_nodes ||= node.children.select { |arg_node| %i(kwarg kwoptarg).include?(arg_node.type) }
        end

        # @return [::AST::Node, nil]
        def keyword_rest_parameter_node
          @keyword_rest_parameter_node ||= node.children.find { |arg_node| arg_node.type == :kwrestarg }
        end

        # @return [::AST::Node, nil]
        def block_parameter_node
          @block_parameter_node ||= node.children.find { |arg_node| arg_node.type == :blockarg }
        end

        private

        # @param arg_node [::AST::Node]
        # @return [Model::Parameters::Base]
        def parse_arg_node(arg_node)
          case arg_node.type
          when :arg, :optarg
            (name = arg_node.children.first) ? Model::Parameters::Named.new(name) : Model::Parameters::Unnamed.new
          when :mlhs
            mlhs_node = MlhsNode.new(arg_node)
            rest_parameter = mlhs_node.rest_node && parse_single_arg_node(mlhs_node.rest_node)

            Model::Parameters::Multiple.new(
              parameters: mlhs_node.pre_nodes.map(&method(:parse_arg_node)),
              rest_parameter: rest_parameter,
              post_parameters: mlhs_node.post_nodes.map(&method(:parse_arg_node)),
            )
          end
        end

        # @param single_arg_node [::AST::Node]
        # @return [Model::Parameters::Base]
        def parse_single_arg_node(single_arg_node)
          single_arg_node.children.first ? Model::Parameters::Named.new(single_arg_node.children.first) : Model::Parameters::Unnamed.new
        end
      end
    end
  end
end
