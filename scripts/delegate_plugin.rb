require 'yard'

class DelegateHandler < YARD::Handlers::Ruby::Base
  handles method_call(:delegate)
  namespace_only

  def process
    first_param = statement.parameters.first.first
    case first_param.type
    when :assoc
      assoc_key, assoc_value, * = first_param.to_a

      extracted_keys = extract(assoc_key)
      extracted_values = extract(assoc_value)

      extracted_key_values = combinations(extracted_keys, extracted_values)

      objects = extracted_key_values.each do |(key, value)|
        obj = register YARD::CodeObjects::MethodObject.new(namespace, key, scope) do |obj|
          signature = "def #{key}(...)"
          obj.signature = signature
          obj.parameters = YARD::Tags::OverloadTag.new(:overload, signature).parameters
        end

        obj.add_tag(YARD::Tags::Tag.new(:delegate, "", nil, "##{value}"))
      end
    end
  end

  # @param [YARD::Parser::Ruby::AstNode] node
  # @return [Array<String>]
  def extract(node)
    case node.type
    when :array
      node.first.to_a.flat_map { |child_node| extract(child_node) }
    when :symbol_literal
      [node.source.delete_prefix(':')]
    else
      []
    end
  end

  # @param [Array<String>] keys
  # @param [Array<String>] values
  # @return [Array<(String, String)>]
  def combinations(keys, values)
    keys.reduce([]) do |acc, key|
      acc + values.map { |value| [key, value] }
    end
  end
end

YARD::Tags::Library.define_tag("delegate", :delegate, :with_name)
