module Yoda
  module Store
    module Adapters
      require 'yoda/store/adapters/base'
      require 'yoda/store/adapters/gdbm_adapter'
      require 'yoda/store/adapters/sqlite_adapter'
      require 'yoda/store/adapters/memory_adapter'

      class << self
        # @return [Class<Base>]
        def default_adapter_class
          SqliteAdapter
        end

        # @param path [String, nil]
        def for(path)
          if path
            default_adapter_class.for(path)
          else
            MemoryAdapter.new
          end
        end

        # @return [Hash{Symbol => Base}]
        def adapter_classes
          @adapter_classes ||= [GdbmAdapter, SqliteAdapter, MemoryAdapter].map { |klass| [klass.type.to_sym, klass] }.to_h
        end
      end
    end
  end
end
