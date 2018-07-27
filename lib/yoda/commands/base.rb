module Yoda
  module Commands
    # @abstract
    class Base
      def self.run(*args)
        self.new(*args).run
      end
    end
  end
end
