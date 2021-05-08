module Yoda
  module Model
    module FunctionSignatures
      class RbsMethod < Base
        # @return [RBS::Definition]
        attr_reader :rbs_definition

        # @return [RBS::Definition::Method]
        attr_reader :rbs_method_definition

        # @return [RBS::Definition::Method::TypeDef]
        attr_reader :rbs_method_typedef

        # @param rbs_definition [RBS::Definition]
        # @param rbs_method_definition [RBS::Definition::Method]
        # @param rbs_method_typedef [RBS::Definition::Method::TypeDef]
        def initialize(rbs_definition:, rbs_method_definition:, rbs_method_typedef:)
          @rbs_definition = rbs_definition
          @rbs_method_definition = rbs_method_definition
          @rbs_method_typedef = rbs_method_typedef
        end

        # @return [TypeExpressions::FunctionType]
        def type
          fail NotImplementedError
        end

        def sep
          rbs_definition.instance_type? ? "#" : "."
        end

        # @return [RBS::MethodType]
        def rbs_type(_env)
          rbs_method_typedef.type
        end

        # @return [Symbol]
        def visibility
          rbs_method_definition.accessibility
        end

        # @return [String]
        def name
          rbs_method_typedef.member.name.to_s
        end

        # @return [String]
        def namespace_path
          rbs_definition.type_name.to_s
        end

        # @return [String]
        def document
          rbs_method_typedef.comment.string
        end

        # @abstract
        # @return [ParameterList]
        def parameters
          ParameterList.from_rbs_method_type(rbs_method_typedef.type)
        end

        # @return [Array<(String, Integer, Integer)>]
        def sources
          location = rbs_method_typedef.comment.location
          if location
            [[location.name, *location.start_loc]]
          else
            []
          end
        end

        # @return [String]
        def to_s
          "#{name}#{rbs_method_typedef.type.to_s}"
        end

        # @abstract
        # @return [TypeExpressions::Base, nil]
        def parameter_type_of(param)
          fail NotImplementedError
        end
      end
    end
  end
end
