module Yoda
  module Services
    class CodeCompletion
      class KeywordProvider < BaseProvider
        KEYWORDS = %i(
          __ENCODING__
          __LINE__
          __FILE__
          BEGIN
          END
          alias
          and
          begin
          break
          case
          class
          def
          defined?
          do
          else
          elsif
          end
          ensure
          false
          for
          if
          in
          module
          next
          nil
          not
          or
          redo
          rescue
          retry
          return
          self
          then
          true
          undef
          unless
          until
          when
          while
          yield
        )


        # @return [true, false]
        def providable?
          true
        end

        # Returns constant candidates by using the current lexical scope.
        # @return [Array<Model::CompletionItem>] constant candidates.
        def candidates
        end

        private

        def current_node
          @current_nnode ||= source_analyzer.nodes_to_current_location_from_root.last
        end
      end
    end
  end
end
