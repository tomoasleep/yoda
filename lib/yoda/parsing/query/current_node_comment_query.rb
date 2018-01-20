module Yoda
  module Parsing
    module Query
      class CurrentNodeCommentQuery
        attr_reader :ast, :comments, :location

        # @param ast      [::Parser::AST::Node]
        # @param comments [Array<::Parser::Source::Comment>]
        # @param location [Location]
        def initialize(comments, location)
          @ast = ast
          @comments = comments
          @location = location
        end

        # @return [Array<::Parser::Source::Comment>]
        def current_commenting_node
          @current_commenting_node ||= inverse_association[current_comment_block]
        end

        private

        # @return [{::Parser::AST::Node => Array<::Parser::Source::Comment>}]
        def association
          @association ||= ::Parser::Source::Comment.associate(ast, comments)
        end

        # @return [{Array<::Parser::Source::Comment> => ::Parser::AST::Node}]
        def inverse_association
          @inverse_association ||= association.invert
        end

        # @return [{::Parser::Source::Map => Array<::Parser::Source::Comment>]
        def location_association
          @location_association ||= ::Parser::Source::Comment.associate_with_location(ast, comments)
        end
      end
    end
  end
end
