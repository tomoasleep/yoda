require 'forwardable'
require 'pp'

module Yoda
  module Typing
    module Tree
      class Comment
        extend Forwardable

        # @return [AST::CommentBlock]
        attr_reader :comment

        # @return [Inferencer::Tracer]
        attr_reader :tracer

        # @return [Contexts::BaseContext]
        attr_reader :context

        delegate [:bind_tree, :bind_context, :bind_type, :bind_send, :bind_method_definition, :bind_require_paths] => :tracer

        # @return [Types::Generator]
        delegate [:generator] => :context

        # @param comment [AST::CommentBlock]
        # @param tracer [Inferencer::Tracer]
        # @param context [Contexts::BaseContext]
        def initialize(comment:, tracer:, context:)
          @comment = comment
          @tracer = tracer
          @context = context
        end

        # Process @type tag in the source code.
        # @see https://www.jetbrains.com/help/ruby/documenting-source-code.html#add_type_tag
        # @return [void]
        def process
          @processed ||= begin
            comment.tag_parts.each do |tag_part|
              process_tag(tag_part)
            end

            true
          end
        end

        # @param pp [PP]
        def pretty_print(pp)
          pp.object_group(self) do
            pp.breakable
            pp.text "@comment="
            pp.pp comment
            pp.text "@context="
            pp.pp context
            pp.comma_breakable
            pp.text "@tracer="
            pp.pp tracer
          end
        end

        def inspect
          pretty_print_inspect
        end

        private

        # @param tag_part [AST::CommentBlock::TagPart]
        def process_tag(tag_part)
          tag = tag_part.to_tag(lexical_scope: context.lexical_scope_types.flat_map { |type| type.value.referred_objects.map(&:path) })
          case tag.tag_name.to_sym
          when :type
            if tag.name
              rbs_type = tag.type_expression.to_rbs_type(context.environment)
              context.type_binding.bind(tag.name, generator.wrap_rbs_type(rbs_type))
            end
          end
        end
      end
    end
  end
end
