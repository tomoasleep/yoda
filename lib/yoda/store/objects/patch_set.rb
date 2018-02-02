module Yoda
  module Store
    module Objects
      # PatchSet manages patch updates and patch outdates.
      # Besides, this class provides api to modify objects by using owning patches.
      class PatchSet
        # @return [{ Symbol => ::Set<Symbol> }]
        attr_reader :address_index

        # @return [{ Symbol => Patch }]
        attr_reader :patches

        # @param id [String]
        def initialize(id)
          @id = id
          @patches = Hash.new
          @address_index = Hash.new
        end

        # @param patch [Patch]
        # @return [void]
        def register(patch)
          register_to_index(patch)
          patches[patch.id.to_sym] = patch
        end

        # @param id [String, Symbol]
        def delete(id)
          patches.delete(id.to_sym)
        end

        # @param object [Addressable]
        # @return [Addressable]
        def patch(object)
          check_outdated_index(object.address.to_sym)
          (address_index[address.to_sym] || []).reduce(object) do |obj, patch_id|
            obj.merge(patches[patch_id].find(address.to_sym))
          end
        end

        # @param address [String, Symbol]
        # @return [Addressable, nil]
        def find(address)
          check_outdated_index(address.to_sym)
          if patch_id = address_index[address.to_sym]
            patches[patch_id].find(address.to_sym)
          else
            nil
          end
        end

        # @return [Array<Symbol>]
        def keys
          address_index.keys
        end

        # @param address [String, Symbol]
        # @return [true, false]
        def has_key?(address)
          check_outdated_index(address.to_sym)
          address_index[address.to_sym] && !address_index[address.to_sym].empty?
        end

        private

        # @param patch [Patch]
        # @return [void]
        def register_to_index(patch)
          patch.keys.each do |key|
            address_index[key.to_sym] ||= Set.new
            address_index[key.to_sym].add(patch.id.to_sym)
          end
        end

        # @param address [Symbol]
        def check_outdated_index(address)
          id_set = address_index[address]
          id_set.to_a.each do |patch_id|
            id_set.delete(patch_id) unless patches[patch_id].has_key?(address)
          end
        end
      end
    end
  end
end
