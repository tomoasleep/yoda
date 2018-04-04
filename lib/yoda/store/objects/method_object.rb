module Yoda
  module Store
    module Objects
      class MethodObject < Base
        # @return [Array<(String, String)>]
        attr_reader :parameters

        # @return [Symbol]
        attr_reader :visibility

        # @return [Array<Overload>]
        attr_reader :overloads

        class << self
          # @param path [String]
          # @return [String]
          def namespace_of_path(path)
            path.slice(0, (path.rindex(/[#.]/) || 0))
          end

          # @param path [String]
          # @return [String]
          def name_of_path(path)
            path.slice((path.rindex(/[#.]/) || -1) + 1, path.length)
          end

          # @param path [String]
          # @return [String]
          def sep_of_path(path)
            path.slice(path.rindex(/[#.]/))
          end

          # @return [Array<Symbol>]
          def attr_names
            super + %i(parameters visibility overloads)
          end
        end

        # @param path [String]
        # @param document [Document, nil]
        # @param tag_list [TagList, nil]
        # @param visibility [Symbol]
        # @param overloads [Array<Overload>]
        # @param parameters [Array<(String, String)>, nil]
        def initialize(parameters: [], visibility: :public, overloads: [], **kwargs)
          super(kwargs)
          fail ArgumentError, visibility unless %i(public private protected)
          @visibility = visibility.to_sym
          @parameters = parameters
          @overloads = overloads
        end

        # @return [String]
        def name
          @name ||= MethodObject.name_of_path(path)
        end

        # @return [String]
        def sep
          @sep ||= MethodObject.sep_of_path(path)
        end

        # @return [String]
        def namespace_path
          @namespace_path ||= MethodObject.namespace_of_path(path)
        end

        def kind
          :method
        end

        def to_h
          super.merge(
            parameters: parameters.to_a,
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
            parameters: another.parameters.to_a,
            overloads: overloads + another.overloads,
          )
        end
      end
    end
  end
end
