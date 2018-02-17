module Yoda
  module Store
    module Query
      class FindSignature < Base
        # @param namespace [Objects::NamespaceObject]
        # @param method_name [String, Regexp]
        # @param visibility [Array<Symbol>, nil]
        # @return [Array<Objects::MethodObject>]
        def select(namespace, method_name, visibility: nil)
          FindMethod.new(registry).select(namespace, method_name, visibility: visibility).map { |el| build(namespace, el) }.flatten
        end

        private

        # @param receiver [Store::Objects::NamespaceObject]
        # @param method_object [Store::Objects::MethodObject]
        # @return [Array<FunctionSignatures::Base>]
        def build(receiver, method_object)
          if method_object.overloads.empty?
            [Model::FunctionSignatures::Method.new(method_object)]
          else
            method_object.overloads.map { |overload| Model::FunctionSignatures::Overload.new(method_object, overload) }
          end
        end
      end
    end
  end
end
