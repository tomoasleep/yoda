require 'set'
require 'forwardable'

module Yoda
  module Store
    class Registry::Index
      class ComposerWrapper
        extend Forwardable

        # @return [Registry::Index]
        attr_reader :index

        # @return [Registry::Composer]
        attr_reader :composer

        delegate id: :composer

        # @param index [Registry::Index]
        # @param composer [Registry::Composer]
        def initialize(index:, composer:)
          fail TypeError, "index must be an instance of Registry::Index but #{index}" unless index.is_a?(Registry::Index)
          fail TypeError, "composer must be an instance of Registry::Composer but #{composer}" unless composer.is_a?(Registry::Composer)
          @index = index
          @composer = composer
        end

        # @param [String, Symbol]
        # @return [Objects::Addressable]
        def get(address)
          composer.get(address, registry_ids: index.get(address))
        end

        def add_registry(registry)
          if old_registry = composer.get_registry(registry.id)
            index.remove_registry(old_registry)
          end
          composer.add_registry(registry)
          index.remember_registry_contents(registry)
        end

        def remove_registry(registry)
          composer.remove_registry(registry)
          index.forget_registry_contents(registry)
        end

        def keys
          index.keys
        end
      end

      include Objects::Serializable

      # @return [Hash]
      attr_reader :content

      def initialize(content: {})
        @content = content
      end

      def to_h
        { content: content }
      end

      # @param address [String, Symbol]
      # @return [Set<Symbol>]
      def get(address)
        content[address.to_sym] ||= Set.new
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
        registry.keys.each { |key| add(key, registry.id) }
      end

      def forget_registry_contents
        registry.keys.each { |key| remove(key, registry.id) }
      end
    end
  end
end