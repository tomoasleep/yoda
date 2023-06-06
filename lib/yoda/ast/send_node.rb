module Yoda
  module AST
    class SendNode < Node
      # @return [Vnode]
      def receiver
        children[0]
      end

      # @return [NameVnode]
      def selector
        children[1]
      end

      # @return [Symbol]
      def selector_name
        selector.name
      end

      # @return [Array<Vnode>]
      def arguments
        children.slice(2..-1)
      end

      # @return [Array<Vnode>]
      def expanded_arguments
        block_pass_arguments, arguments_without_block_pass = arguments.partition { |node| node.type == :block_pass }
        if last_argument = arguments_without_block_pass.last
          arguments_without_block_pass.slice(0..-2) + (last_argument.type == :hash ? last_argument.children : [last_argument]) + block_pass_arguments
        else
          arguments_without_block_pass.slice(0..-2) + block_pass_arguments
        end
      end

      def keyword_argument
        non_bpass_arguments = arguments.reject { |node| node.type == :block_pass }
        non_bpass_arguments.last&.type == :hash ? non_bpass_arguments.last : nil
      end

      def block_pass_argument
        arguments.last.type == :block_pass ? arguments.last : nil
      end

      def implicit_receiver?
        receiver.empty?
      end

      # @return [true, false]
      def on_selector?(location)
        source_map.selector ? selector_range.include?(location) : false
      end

      # @param location [Parsing::Location]
      # @return [true, false]
      def on_dot?(location)
        source_map.dot ? dot_range.include?(location) : false
      end

      # @param location [Parsing::Location]
      # @return [true, false]
      def on_arguments?(location)
        arguments_range.include?(location)
      end

      # @return [Parsing::Range]
      def range_without_arguments
        @range_without_arguments ||=
          Parsing::Range.new(
            Parsing::Location.of_ast_location(source_map.expression.begin),
            Parsing::Location.of_ast_location(source_map.selector.end),
          )
      end

      # @return [Parsing::Range]
      def arguments_range
        @arguments_range ||=
          Parsing::Range.new(
            Parsing::Location.of_ast_location(source_map.selector.end),
            Parsing::Location.of_ast_location(source_map.expression.end).move(row: 0, column: -1),
          )
      end

      # @return [Parsing::Range]
      def selector_range
        @selector_range ||= Parsing::Range.of_ast_location(source_map.selector)
      end

      # @return [Parsing::Range, nil]
      def dot_range
        @dot_range ||= source_map.dot && Parsing::Range.of_ast_location(source_map.dot)
      end

      # @return [Parsing::Location, nil]
      def next_location_to_dot
        source_map.dot && Parsing::Range.of_ast_location(source_map.dot).end_location
      end

      # @return [String]
      def selector_name
        selector.name.to_s
      end

      # @param location [Parsing::Location]
      # @return [Integer]
      def offset_in_selector(location)
        location.offset_from_begin(source_map.selector)[:column]
      end
    end
  end
end
