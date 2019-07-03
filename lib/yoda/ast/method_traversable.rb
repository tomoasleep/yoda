
module Yoda
  module AST
    module MethodTraversable
      # @return [true, false]
      def method?
        false
      end

      # @return [Namespace]
      def including_method
        @including_method ||= method? ? self : parent.including_method
      end

      # @param location [Location]
      # @return [DefNode, DefSingletonNode, nil]
      def calc_current_location_method(location)
        positionally_nearest_child(location)&.including_method
      end
    end
  end
end
