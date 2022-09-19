require 'sqlite3'
require 'yoda/store/adapters/base'

module Yoda
  module Store
    module Adapters
      class SqliteAdapter < Base
        require 'yoda/store/adapters/sqlite_adapter/database_accessor'
        require 'yoda/store/adapters/sqlite_adapter/namespace_accessor'

        class << self
          def for(path)
            @pool ||= {}
            @pool[path_for(path)] || (@pool[path_for(path)] = new(path_for(path)))
          end

          def type
            :sqlite
          end

          def clean
            @pool&.each { |(_, db)| db.close }
            @pool = nil
          end
        end

        # @return [DatabaseAccessor]
        attr_reader :database_accessor
        private :database_accessor

        extend Forwardable
        delegate [:get, :batch_write, :put, :delete, :exists, :keys, :clear, :empty?, :persistable?] => :root

        # @param path [String]
        def initialize(path)
          @path = path
          @database_accessor = DatabaseAccessor.open(path)
        end

        def root
          @root ||= NamespaceAccessor.new(database_accessor: database_accessor, namespace: nil)
        end

        def close
          database_accessor.close
        end

        # @param namespace [String, Symbol]
        # @return [NamespaceAccessor]
        def namespace_for(name)
          @namespaces ||= {}
          @namespaces[name.to_sym] ||= NamespaceAccessor.new(database_accessor: database_accessor, namespace: name)
        end
        alias :namespace :namespace_for

        # @return [String]
        def inspect
          "#<#{self.class.name}: #{self.class.type}>"
        end
      end
    end
  end
end
