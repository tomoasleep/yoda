require 'yoda/typing/contexts/base_context'

module Yoda
  module Typing
    module Contexts
      class MethodContext < BaseContext
        # @return [Context, nil]
        def parent_for_environment
          nil
        end
      end
    end
  end
end
