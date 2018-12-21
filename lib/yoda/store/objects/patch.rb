module Yoda
  module Store
    module Objects
      class Patch
        # @param id [String]
        attr_reader :id

        # @param registry [Hash{ Symbol => Addressable }]
        attr_reader :registry

        # @param id [String]
        # @param  [Array[Addressable], nil]
        def initialize(id, contents = nil)
          @id = id
          @registry = (contents || []).map { |content| [content.address.to_sym, content] }.to_h
        end

        # @param address [String, Symbol]
        # @return [Addressable, nil]
        def find(address)
          @registry[address.to_sym]
        end

        # @param address [String, Symbol]
        # @return [true, false]
        def has_key?(address)
          @registry.has_key?(address.to_sym)
        end

        # @return [Array<Symbol>]
        def keys
          @registry.keys
        end

        # @param addressable [Addressable]
        # @return [void]
        def register(addressable)
          parent_modifier.add_address_to_parent(addressable)

          if el = @registry[addressable.address.to_sym]
            @registry[addressable.address.to_sym] = el.merge(addressable)
          else
            @registry[addressable.address.to_sym] = addressable
          end
        end

        private

        def parent_modifier
          @parent_modifier ||= ParentModifier.new(self)
        end

        class ParentModifier
          attr_reader :patch

          # @param patch [Patch]
          def initialize(patch)
            @patch = patch
          end

          # @param code_object [Base]
          # @return [void]
          def add_address_to_parent(code_object)
            parent_module = patch.find(code_object.parent_address) || create_parent_module(code_object)
            return unless parent_module.namespace?
            patch.register(parent_module) if !patch.has_key?(parent_module.address) && parent_module.address != code_object.address

            case code_object.kind
            when :method
              parent_module.instance_method_addresses.push(code_object.address) unless parent_module.instance_method_addresses.include?(code_object.address)
            when :class, :module, :value
              parent_module.constant_addresses.push(code_object.address) unless parent_module.constant_addresses.include?(code_object.address)
            end
          end

          def create_parent_module(code_object)
            if code_object.address == code_object.parent_address
              code_object
            elsif MetaClassObject.meta_class_address?(code_object.parent_address)
              MetaClassObject.new(path: MetaClassObject.path_of(code_object.parent_address))
            else
              ModuleObject.new(path: code_object.parent_address)
            end
          end
        end
      end
    end
  end
end
