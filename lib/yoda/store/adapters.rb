module Yoda
  module Store
    module Adapters
      require 'yoda/store/adapters/base'
      require 'yoda/store/adapters/leveldb_adapter'
      require 'yoda/store/adapters/lmdb_adapter'

      # @return [Base.class]
      def self.default_adapter_class
        LmdbAdapter
      end
    end
  end
end
