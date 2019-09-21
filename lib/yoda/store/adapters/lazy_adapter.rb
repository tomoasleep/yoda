require 'forwardable'

module Yoda
  module Store
    module Adapters
      class LazyAdapter < Base
        class << self
          def for(path, type)
            @pool ||= {}
            @pool[path] || (@pool[path] = new(path))
          end

          def type
            :lazy
          end
        end

        extend Forwardable

        delegate %i(get put delete exist keys stats sync clear batch_write) => :adapter

        # @param path [String] represents the path to store db.
        def initialize(path)
          @path = path
        end

        # @return [Adapters::Base]
        def adapter
          @adapter ||= Adapters.for(path)
        end
      end
    end
  end
end
