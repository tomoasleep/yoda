module Yoda
  module Parsing
    module Query
      # Provides helper methods to find the node whose comment include the current position (is the current comment).
      class CurrentCommentingNodeQuery
        attr_reader :ast, :comments, :location

        # @param ast      [AST::Node]
        # @param comments [Array<::Parser::Source::Comment>]
        # @param location [Location] represents the current position.
        def initialize(ast, comments, location)
          fail ArgumentError, ast unless ast.is_a?(AST::Vnode)
          fail ArgumentError, comments unless comments.all? { |comment| comment.is_a?(::Parser::Source::Comment) }
          fail ArgumentError, location unless location.is_a?(Location)
          @ast = ast
          @comments = comments
          @location = location
        end

        # @return [Array<::Parser::Source::Comment>]
        def current_commenting_node
          @current_commenting_node ||= inverse_association[current_comment_query.current_comment_block]
        end

        # @return [NodeObjects::Namespace, nil]
        def current_namespace
          @current_namespace ||= namespace.calc_current_location_namespace(current_commenting_node_location)
        end

        # @return [NodeObjects::MethodDefition, nil]
        def current_method_definition
          @current_method_definition ||= namespace.calc_current_location_method(current_commenting_node_location)
        end

        private

        def current_commenting_node_location
          @current_commenting_node_location ||= current_commenting_node.location
        end

        # @return [Namespace]
        def namespace
          @namespace ||= ast.namespace
        end

        # @return [{AST::Node => Array<::Parser::Source::Comment>}]
        def association
          @association ||= ast.associate_comments(comments)
        end

        # @return [{Array<::Parser::Source::Comment> => AST::Node}]
        def inverse_association
          @inverse_association ||= association.invert
        end

        # @return [{::Parser::Source::Map => Array<::Parser::Source::Comment>]
        def location_association
          @location_association ||= ::Parser::Source::Comment.associate_with_location(ast, comments)
        end

        # @return [CurrentCommentQuery]
        def current_comment_query
          @current_comment_query ||= CurrentCommentQuery.new(comments, location)
        end
      end
    end
  end
end
