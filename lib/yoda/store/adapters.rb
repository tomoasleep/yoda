module Yoda
  module Store
    module Adapters
      require 'yoda/store/adapters/base'
      require 'yoda/store/adapters/lmdb_adapter'
      require 'yoda/store/adapters/memory_adapter'

      # @return [Class<Base>]
      def self.default_adapter_class
        LmdbAdapter
      end

      def self.for(path)
        default_adapter_class.for(path)
      end
    end
  end
end
