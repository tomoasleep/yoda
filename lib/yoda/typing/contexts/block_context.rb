require 'yoda/typing/contexts/base_context'

module Yoda
  module Typing
    module Contexts
      class BlockContext < BaseContext
        # @return [Context, nil]
        def parent_variable_scope_context
          parent
        end
      end
    end
  end
end
