require 'dbm'
require 'fileutils'
require 'yoda/store/adapters/base'

module Yoda
  module Store
    module Adapters
      class DbmAdapter < Base
        require 'yoda/store/adapters/dbm_adapter/namespace_accessor'

        class << self
          def for(path)
            @pool ||= {}
            @pool[path] || (@pool[path] = new(path))
          end

          def type
            :dbm
          end
        end

        # @return [DBM]
        attr_reader :database
        private :database

        extend Forwardable
        delegate [:get, :batch_write, :put, :delete, :exists, :keys, :clear, :empty?, :persistable?] => :root

        # @param path [String]
        def initialize(path)
          dirname = File.dirname(path)
          FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)
          @path = path
          @database = DBM.open(path, 0666, DBM::WRCREAT)
        end

        def root
          @root ||= NamespaceAccessor.new(database: database, namespace: nil)
        end

        # @param namespace [String, Symbol]
        # @return [NamespaceAccessor]
        def namespace_for(name)
          @namespaces ||= {}
          @namespaces[name.to_sym] ||= NamespaceAccessor.new(database: database, namespace: name)
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
