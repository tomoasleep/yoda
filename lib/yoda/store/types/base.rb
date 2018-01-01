module Yoda
  module Store
    module Types
      # @abstract
      class Base
        def ==(another)
          eql?(another)
        end

        # @abstract
        # @param namespace [YARD::CodeObjects::Base]
        # @return [Base]
        def change_root(namespace)
          fail NotImplementedError
        end
      end
    end
  end
end
