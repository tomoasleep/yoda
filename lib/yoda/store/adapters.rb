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

      # @param path [String, nil]
      def self.for(path)
        if path
          default_adapter_class.for(path)
        else
          MemoryAdapter.new
        end
      end
    end
  end
end
