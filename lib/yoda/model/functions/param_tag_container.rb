module Yoda
  module Store
    module Functions
      module ParamTagContainer

        # @return [Array<String>]
        def parameter_names
          parameters.map(&:first)
        end

        # @abstract
        # @return [Array<(String, String)>]
        def parameters
          fail NotImplementedError
        end

        private

        # @return [{ String => Type }]
        def param_types
          @param_types ||= param_tags.group_by(&:name).transform_values { |tags| parse_param_tag_type(tags.map(&:types).flatten) }
        end

        # @param type_strings [Array<String>]
        # @return [Types::Base]
        def parse_param_tag_type(type_strings)
          (type_strings.empty? ? Types::UnknownType.new('nodoc') : Types.parse_type_strings(type_strings)).change_root(namespace)
        end

        # @return [Hash]
        def parameter_options
          parameters.each_with_object({}) do |(name, default), obj|
            obj[:parameters] ||= []
            obj[:parameters].push([name, param_types[name] || Types::UnknownType.new('nodoc'), default])
          end
        end

        # @abstract
        # @return [Array<(String, String)>]
        def param_tags
          fail NotImplementedError
        end

        # @abstract
        # @return [YARD::CodeObjects::Base]
        def namespace
          fail NotImplementedError
        end
      end
    end
  end
end
