require 'yoda/typing/constant_resolver/query'

module Yoda
  module Typing
    class ConstantResolver
      class RelativeBaseQuery < Query
        # @return [nil]
        def parent
          nil
        end
      end
    end
  end
end
