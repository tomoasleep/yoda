require 'set'

module Yoda
  module Store
    module Objects
      # PatchSet manages patch updates and patch outdates.
      # Besides, this class provides api to modify objects by using owning patches.
      class PatchSet
        class AddressIndex
          def initialize
            @index = Hash.new
          end

          # @param address [Symbol]
          # @return [Set<Symbol>]
          def get(address, **)
            index[address] ||= Set.new
          end

          # @return [Set<Symbol>]
          def keys
            index.keys
          end

          # @param patch [Patch]
          # @return [void]
          def register(patch)
            patch.keys.each do |key|
              index[key.to_sym] ||= Set.new
              index[key.to_sym].add(patch.id.to_sym)
            end
          end

          # @param patch [Patch]
          # @return [void]
          def delete(patch)
            patch.keys.each do |key|
              (index[key.to_sym] || []).delete(patch.id.to_sym)
            end
          end

          private
          # @return [{ Symbol => Array<Symbol> }]
          attr_reader :index
        end

        # @param init_patches [Array<Patch>]
        def initialize(init_patches = [], id: nil)
          @id = id
          @patches = Hash.new
          @address_index = AddressIndex.new
          init_patches.each { |patch| register(patch) }
        end

        # @param patch [Patch]
        # @return [void]
        def register(patch)
          address_index.register(patch)
          patches[patch.id.to_sym] = patch
        end

        # @param id [String, Symbol]
        def delete(id)
          if patch = patches[id.to_sym]
            address_index.delete(patch)
          end
          patches.delete(id.to_sym)
        end

        # @param object [Addressable]
        # @return [Addressable]
        def patch(object)
          objects_in_patch = get_patches(object.address)
          Merger.new([object, *objects_in_patch]).merged_instance
        end

        # @param address [String, Symbol]
        # @return [Addressable, nil]
        def find(address, **)
          if (patches = get_patches(address)).empty?
            nil
          else
            Merger.new(patches).merged_instance
          end
        end
        alias get find

        # @return [Array<Symbol>]
        def keys
          address_index.keys.to_a
        end

        # @param address [String, Symbol]
        # @return [true, false]
        def has_key?(address)
          !address_index.get(address.to_sym).empty?
        end

        private

        # @return [AddressIndex]
        attr_reader :address_index

        # @return [{ Symbol => Patch }]
        attr_reader :patches

        # @param address [String, Symbol]
        # @return [Array<Patch>]
        def get_patches(address)
          patch_ids = address_index.get(address.to_sym)
          patch_ids.map { |id| patches[id].find(address.to_sym) }
        end
      end
    end
  end
end
