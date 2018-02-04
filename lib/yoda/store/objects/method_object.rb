module Yoda
  module Store
    module Objects
      class MethodObject < Base
        # @return [Array<(String, String)>, nil]
        attr_reader :parameters

        # @return [Symbol]
        attr_reader :visibility

        # @return [Array<Overload>]
        attr_reader :overloads

        # @param path [String]
        # @return [String]
        def self.name_of_path(path)
          path.match(METHOD_PATTERN) { |md| md[1] }
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
          @visibility = visibility
          @parameters = parameters
          @overloads = overloads
        end

        # @return [String]
        def name
          @name ||= MethodObject.name_of_path(path)
        end

        # @return [String]
        def sep
          @sep ||= path.match(METHOD_PATTERN) { |md| md[0] }
        end

        def type
          :method
        end

        def to_h
          super.merge(
            parameters: parameters,
            visibility: visibility,
          )
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          super.merge(
            visibility: another.visibility,
            parameters: another.parameters,
          )
        end
      end
    end
  end
end
