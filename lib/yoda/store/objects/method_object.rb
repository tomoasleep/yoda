module Yoda
  module Store
    module Objects
      class MethodObject < Base
        class Connected < Base::Connected
          delegate_to_object :parameters, :visibility, :overloads, :name, :separator, :namespace_path, :parent_address, :namespace_path
        end

        # @return [Model::FunctionSignatures::ParameterList]
        attr_reader :parameters

        # @return [Symbol]
        attr_reader :visibility

        # @return [Array<Overload>]
        attr_reader :overloads

        class << self
          # @return [Array<Symbol>]
          def attr_names
            super + %i(parameters visibility overloads)
          end
        end

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [Array<Tag>, nil]
        # @param visibility [Symbol]
        # @param overloads [Array<Overload>]
        # @param parameters [Array<(String, String)>, nil]
        def initialize(parameters: [], visibility: :public, overloads: [], **kwargs)
          super(**kwargs)
          fail ArgumentError, visibility unless %i(public private protected)
          @visibility = visibility.to_sym
          @parameters = Model::FunctionSignatures::ParameterList.new(parameters)
          @overloads = overloads
        end

        # @return [String]
        def name
          address.name
        end

        # @return [String]
        def separator
          address.separator
        end

        # @return [String]
        def namespace_path
          address.namespace.to_s
        end

        # @return [String]
        def parent_address
          @parent_address ||= begin
            case separator
            when '#'
              namespace_path
            when '.', '::'
              MetaClassObject.address_of(namespace_path)
            else
              fail TypeError
            end
          end
        end

        def kind
          :method
        end

        def to_h
          super.merge(
            parameters: parameters.raw_parameters.to_a,
            visibility: visibility,
            overloads: overloads,
          )
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            visibility: another.visibility,
            parameters: another.parameters.raw_parameters.to_a,
            overloads: overloads + another.overloads,
          )
        end
      end
    end
  end
end
