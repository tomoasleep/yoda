module Yoda
  module Store
    module Values
      # @abstract
      class Base
        # @abstract
        # @return [Array<Functions::Base>]
        def methods
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def path
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def docstring
          fail NotImplementedError
        end

        # @abstract
        # @return [Array<[String, Integer]>]
        def defined_files
          fail NotImplementedError
        end
      end
    end
  end
end
