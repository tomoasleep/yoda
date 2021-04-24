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
          METHOD_SEPARATOR_PATTERN = /[#.]|(::)/

          # @param path [String]
          # @return [String]
          def namespace_of_path(path)
            divide_by_separator(path)&.at(0)
          end

          # @param path [String]
          # @return [String]
          def name_of_path(path)
            divide_by_separator(path)&.at(2)
          end

          # @param path [String]
          # @return [String, nil]
          def sep_of_path(path)
            divide_by_separator(path)&.at(1)
          end

          # @return [Array<Symbol>]
          def attr_names
            super + %i(parameters visibility overloads)
          end

          private

          # @param path [String]
          # @return [(String, String, String), nil]
          def divide_by_separator(path)
            rev_path = path.reverse
            if match_data = rev_path.match(METHOD_SEPARATOR_PATTERN)
              [match_data.post_match.reverse, match_data.to_s, match_data.pre_match.reverse]
            else
              nil
            end
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

        # @return [String]
        def parent_address
          @parent_address ||= begin
            case MethodObject.sep_of_path(path)
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
