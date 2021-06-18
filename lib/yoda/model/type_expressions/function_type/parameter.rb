module Yoda
  module Model
    module TypeExpressions
      class FunctionType
        class Parameter
          # @return [String, nil]
          attr_reader :name

          # @return [Base]
          attr_reader :type

          # @param name [String, nil]
          # @param type [Base]
          def initialize(name: nil, type:)
            @name = name
            @type = type
          end

          # @param env [Environment]
          # @return [RBS::Types::Function::Param]
          def to_rbs_param(env)
            RBS::Types::Function::Param.new(type: type.to_rbs_type(env), name: name.to_sym)
          end

          def map_type(&block)
            self.class.new(name: name, type: block.call(type))
          end

          def ==(another)
            eql?(another)
          end

          def eql?(another)
            another.is_a?(Parameter) && name == another.name && type == another.type
          end

          def hash
            [self.class.name, name, type].hash
          end

          # @return [String]
          def keyword_expression(optional: false)
            prefix = optional ? "?" : ""
            "#{prefix}#{name}: #{type}"
          end

          # @return [String]
          def optional_keyword_expression
            keyword_expression(optional: true)
          end

          # @return [String]
          def keyword_rest_expression
            "**#{type} #{name}"
          end

          # @return [String]
          def optional_expression
            positional_expression(optional: true)
          end

          # @return [String]
          def rest_expression
            positional_expression(rest: true)
          end

          # @return [String]
          def block_expression
            positional_expression(block: true)
          end

          # @return [String]
          def positional_expression(optioanl: false, rest: false, block: false)
            prefix = begin
              if optional
                "?" 
              elsif rest
                "*"
              elsif block
                "&"
              else
                ""
              end
            end
            if name
              "#{prefix}#{type} #{name}"
            else
              "#{prefix}#{type}"
            end
          end
        end
      end
    end
  end
end
