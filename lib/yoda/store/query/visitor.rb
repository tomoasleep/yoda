module Yoda
  module Store
    module Query
      # An wrapper of {Enumerator::Yielder} to detect circular references.
      # @private
      class Visitor
        class CircularReferenceError < StandardError
          # @param label [String, nil]
          # @param order [Array<String>, nil]
          def initialize(label, order)
            super("#{label} appears twice in #{order.inspect}")
          end
        end

        # @return [Set<String>]
        attr_reader :visited

        # @return [Array<String>]
        attr_reader :order

        def initialize
          @visited = Set.new
          @order = []
        end

        # @param original [Visitor]
        # @return [self]
        def initialize_copy(original)
          @visited = original.visited.dup
          @order = original.order.dup
          self
        end

        # @return [Visitor]
        def fork
          self.dup
        end

        # @param label [String]
        def visit(label)
          Logger.trace(label)
          mark_visited(label)
        end
        
        private

        def mark_visited(label)
          fail CircularReferenceError.new(label, [label] + order.reverse) if visited.include?(label)

          visited.add(label)
          order.push(label)
        end
      end
    end
  end
end
