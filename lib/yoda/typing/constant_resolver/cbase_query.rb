require 'yoda/typing/constant_resolver/query'

module Yoda
  module Typing
    class ConstantResolver
      class CbaseQuery < Query
        # @return [nil]
        def parent
          nil
        end
      end
    end
  end
end
