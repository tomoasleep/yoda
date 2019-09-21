require 'set'

module Yoda
  module Store
    class Registry::Index
      class ComposerWrapper
        # @return [Registry::Index]
        attr_reader :index

        # @return [Registry::Composer]
        attr_reader :composer

        # @param index [Registry::Index]
        # @param composer [Registry::Composer]
        def initialize(index:, composer:)
          @index = index
          @composer = composer
        end

      # @param [String, Symbol]
      # @return [Objects::Addressable]
        def get(address)
          composer.get(address, from: index.get(address).map { |key| registry.get_registry(key) })
        end

        def add_registry(registry)
          if old_registry = composer.get_registry(registry.id)
            index.forget_registry_contents(old_registry)
          end
          index.remember_registry_contents(registry)
        end

        def remove_registry(registry)
          index.forget_registry_contents(registry)
        end

        def keys
          index.keys
        end
      end

      include Serializable

      def initialize(content: {})
        @content = content
      end

      def to_h
        { content: content }
      end

      # @param address [String, Symbol]
      # @return [Set<Symbol>]
      def get(address)
        content[address.to_sym] || Set.new
      end

      # @param address [String, Symbol]
      # @param registry_id [String, Symbol]
      def add(address, registry_id)
        content[address.to_sym] ||= Set.new
        content[address.to_sym].add(registry_id)
      end

      # @param address [String, Symbol]
      # @param registry_id [String, Symbol]
      def remove(address, registry_id)
        content[address.to_sym] ||= Set.new
        content[address.to_sym].delete(registry_id)
      end

      def keys
        Set.new(content.keys)
      end

      def remember_registry_contents(registry)
        registry.each_keys { |key| add(address, registry.id) }
      end

      def forget_registry_contents
        registry.each_keys { |key| remove(address, registry.id) }
      end
    end
  end
end