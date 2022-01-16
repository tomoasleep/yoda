module Yoda
  module Services
    class CurrentNodeExplain
      class CommentSignature
        # @return [AST::CommentBlock]
        attr_reader :comment

        # @return [Parsing::Location]
        attr_reader :location

        # @return [Typing::NodeInfo]
        attr_reader :node_info

        # @param comment [AST::CommentBlock]
        # @param location [Parsing::Location]
        # @param node_info [Typing::NodeInfo]
        def initialize(comment:, location:, node_info:)
          @comment = comment
          @location = location
          @node_info = node_info
        end

        # @return [Range, nil]
        def node_range
          current_comment_token&.range
        end

        # @return [Array<Descriptions::Base>]
        def descriptions
          [node_type_description, *type_descriptions].compact
        end

        # @return [Array<String>]
        def defined_files
          objects.map { |value| value.primary_source || value.sources.first }.compact
        end

        # @return [Descriptions::Base]
        def node_type_description
          if constants_type
            Model::Descriptions::CommentTokenDescription.new(current_comment_token, constants_type)
          end
        end

        # @return [Array<Descriptions::Base>]
        def type_descriptions
          objects.map { |object| Model::Descriptions::ValueDescription.new(object) }
        end

        private

        # @return [Array<Store::Objects::Base>]
        def objects
          constants_type&.value&.referred_objects || []
        end

        # @return [AST::CommentBlock::Token, nil]
        def current_comment_token
          part = comment.nearest_tag_part(location)
          part&.type_part&.nearest_token(location)
        end

        # @return [Typing::Types::Type, nil]
        def constants_type
          @constants_type ||= begin
            current_comment_token && node_info.resolve_constant(current_comment_token.content)
          end
        end
      end
    end
  end
end
