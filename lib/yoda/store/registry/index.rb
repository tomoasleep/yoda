require 'set'
require 'forwardable'

module Yoda
  module Store
    class Registry::Index
      class ComposerWrapper
        extend Forwardable
        include MissingDelegatable

        delegate_missing :composer

        # @return [Registry::Index]
        attr_reader :index

        # @return [Registry::Composer]
        attr_reader :composer

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
          index.add_registry(registry)
        end

        def remove_registry(registry)
          composer.remove_registry(registry)
          index.remove_registry(registry)
        end

        def keys
          index.keys
        end
      end

      # @return [Hash]
      attr_reader :content

      # @return [Set]
      attr_reader :registry_ids

      def initialize(content: {}, registry_ids: Set.new)
        @content = content
        @registry_ids = Set.new(registry_ids)
      end

      # @param address [String, Symbol]
      # @return [Set<Symbol>]
      def get(address)
        content[address.to_sym] ||= Objects::SerializableSet.new
      end

      # @param address [String, Symbol]
      # @param registry_id [String, Symbol]
      def add(address, registry_id)
        content[address.to_sym] ||= Objects::SerializableSet.new
        content[address.to_sym].add(registry_id)
        content[address.to_sym].select! { |id| registry_ids.member?(id) }
      end

      # @param address [String, Symbol]
      # @param registry_id [String, Symbol]
      def remove(address, registry_id)
        content[address.to_sym] ||= Objects::SerializableSet.new
        content[address.to_sym].delete(registry_id)
      end

      def keys
        Set.new(content.keys)
      end

      def add_registry(registry)
        registry_ids.add(registry.id)
        registry.keys.each { |key| add(key, registry.id) }
      end

      def remove_registry(registry)
        registry_ids.delete(registry.id)
      end

      def wrap(composer)
        ComposerWrapper.new(composer: composer, index: self)
      end
    end
  end
end
