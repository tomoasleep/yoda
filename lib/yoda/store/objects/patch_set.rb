module Yoda
  module Store
    module Objects
      # PatchSet manages patch updates and patch outdates.
      # Besides, this class provides api to modify objects by using owning patches.
      class PatchSet
        # @return [{ Symbol => Array<Symbol> }]
        attr_reader :address_index

        # @return [{ Symbol => Patch }]
        attr_reader :patches

        def initialize
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
          objects_in_patch = (address_index[object.address.to_sym] || []).map { |patch_id| patches[patch_id].find(object.address.to_sym) }
          Merger.new([object, *objects_in_patch]).merged_instance
        end

        # @param address [String, Symbol]
        # @return [Addressable, nil]
        def find(address)
          check_outdated_index(address.to_sym)
          if (patch_ids = address_index[address.to_sym] || []).empty?
            nil
          else
            objects = patch_ids.map { |id| patches[id].find(address.to_sym) }
            objects.reduce { |obj1, obj2| obj1.merge(obj2) }
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
            address_index[key.to_sym] ||= []
            address_index[key.to_sym].push(patch.id.to_sym)
          end
        end

        # @param address [Symbol]
        def check_outdated_index(address)
          (address_index[address] || []).select! { |patch_id| patches[patch_id].has_key?(address) }
        end
      end
    end
  end
end
