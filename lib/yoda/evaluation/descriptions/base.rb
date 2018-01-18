module Yoda
  module Evaluation
    module Descriptions
      # @abstract
      class Base
        # @abstract
        # @return [String]
        def title
          fail NotImplementedError
        end
        
        # @abstract
        # @return [String]
        def to_markdown
          fail NotImplementedError
        end
      end
    end
  end
end
