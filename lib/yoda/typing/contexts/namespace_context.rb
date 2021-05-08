require 'yoda/typing/contexts/base_context'

module Yoda
  module Typing
    module Contexts
      class NamespaceContext < BaseContext
        # @return [Context, nil]
        def parent_variable_scope_context
          nil
        end
      end
    end
  end
end
