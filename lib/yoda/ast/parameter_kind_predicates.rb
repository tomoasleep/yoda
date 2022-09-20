module Yoda
  module AST
    module ParameterKindPredicates
      # @return [Boolean]
      def parameter?
        %i(arg optarg mlhs).include?(self.type)
      end

      # @return [Boolean]
      def rest_parameter?
        self.type == :restarg
      end

      # @return [Boolean]
      def keyword_parameter?
        %i(kwarg kwoptarg).include?(self.type)
      end

      # @return [Boolean]
      def keyword_rest_parameter?
        self.type == :kwrestarg
      end

      # @return [Boolean]
      def block_parameter?
        self.type == :blockarg
      end

      # @return [Boolean]
      def forward_parameter?
        %i(forward_arg forward-args).include?(self.type)
      end
    end
  end
end
