require 'forwardable'

module Yoda
  module Model
    module FunctionSignatures
      class ParameterList
        class Item
          # @return [:required, :optional, :rest, :post, :required_keyword, :optional_keyword, :keyword_rest, :block]
          attr_reader :kind

          # @return [String]
          attr_reader :name

          # @return [String, nil]
          attr_reader :default

          VALID_KINDS = %i(required optional rest post required_keyword optional_keyword keyword_rest block).freeze

          # @param kind [:required, :optional, :rest, :post, :required_keyword, :optional_keyword, :keyword_rest, :block]
          # @param name [String]
          # @param default [String, nil]
          def initialize(kind:, name:, default: nil)
            fail ArgumentError, "Invalid kind: #{kind}" unless VALID_KINDS.include?(kind)
            @kind = kind
            @name = name
            @default = default
          end

          # @return [Boolean]
          def positional?
            %i(required optional rest post).include?(kind)
          end

          # @return [Boolean]
          def required?
            %i(required post required_keyword).include?(kind)
          end

          # @return [Boolean]
          def keyword?
            %i(required_keyword optional_keyword).include?(kind)
          end

          # @param kind_to_name [Symbol]
          # @return [Boolean]
          def kind?(kind_to_match)
            fail ArgumentError, "Invalid kind: #{kind}" unless VALID_KINDS.include?(kind_to_match)
            kind == kind_to_match
          end
        end

        include Enumerable
        extend Forwardable

        delegate :empty? => :items

        # @return [Array<(String, String)>]
        attr_reader :raw_parameters

        # @param type [RBS::MethodType]
        def self.from_rbs_method_type(type)
          func = type.type

          parameters = []
          parameters += func.required_positionals.map { |param| [param.name, ""] }
          parameters += func.optional_positionals.map { |param| [param.name, ""] }
          parameters += ["*#{type.rest_positionals.name}", ""] if func.rest_positionals
          parameters += func.trailing_positionals.map { |param| [param.name, ""] }
          parameters += func.required_keywords.map { |param| ["#{param.name}:", ""] }
          parameters += func.optional_keywords.map { |param| ["#{param.name}:", ""] }
          parameters += ["**#{func.rest_keywords.name}", ""] if func.rest_keywords
          parameters += ["&block", ""] if type.block

          new(parameters)
        end

        # @param parameters [Array<(String, String)>]
        def initialize(raw_parameters)
          fail ArgumentError, raw_parameters unless raw_parameters.all? { |param| param.is_a?(Array) }
          @raw_parameters = raw_parameters
        end

        # @return [Array<Item>]
        def to_a
          items
        end

        # @return [Enumerator<(String, String)>]
        def each(*args, &proc)
          to_a.each(*args, &proc)
        end

        # @return [Array<String>]
        def parameter_names
          raw_parameters.map(&:first)
        end

        # @return [Array<Item>]
        def required_parameters
          items.select { |item| item.kind?(:required) }
        end

        # @return [Array<Item>]
        def post_parameters
          items.select { |item| item.kind?(:post) }
        end

        # @return [Array<Item>]
        def optional_parameters
          items.select { |item| item.kind?(:optional) }
        end

        # @return [Array<Item>]
        def required_keyword_parameters
          items.select { |item| item.kind?(:required_keyword) }
        end

        # @return [Array<Item>]
        def optional_keyword_parameters
          items.select { |item| item.kind?(:optional_keyword) }
        end

        # @return [Item, nil]
        def rest_parameter
          items.find { |item| item.kind?(:rest) }
        end

        # @return [Item, nil]
        def keyword_rest_parameter
          items.find { |item| item.kind?(:keyword_rest) }
        end

        # @return [Item, nil]
        def block_parameter
          items.find { |item| item.kind?(:block) }
        end

        # @param name [String]
        # @return [Item, nil]
        def find_by_name(name)
          items.find { |item| item.name == name }
        end

        def each(&block)
          items.each(&block)
        end

        # @return [Array<Item>]
        def items
          @items ||= begin
            found_rest = false

            raw_parameters.map do |(name, default)|
              if name.to_s.start_with?('**')
                Item.new(kind: :keyword_rest, name: name.to_s.gsub(/\A\*\*/, ''))
              elsif name.to_s.start_with?('*')
                found_rest = true
                Item.new(kind: :rest, name: name.to_s.gsub(/\A\*/, ''))
              elsif name.to_s.start_with?('&')
                Item.new(kind: :block, name: name.to_s.gsub(/\A\&/, ''))
              elsif name.to_s.end_with?(':')
                if default && !default.empty?
                  Item.new(kind: :optional_keyword, name: name.to_s.gsub(/:\Z/, ''), default: default)
                else
                  Item.new(kind: :required_keyword, name: name.to_s.gsub(/:\Z/, ''))
                end
              elsif default && !default.empty?
                Item.new(kind: :optional, name: name.to_s, default: default)
              elsif found_rest
                Item.new(kind: :post, name: name.to_s)
              else
                Item.new(kind: :required, name: name.to_s)
              end
            end
          end
        end
      end
    end
  end
end
