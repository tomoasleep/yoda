module Yoda
  module Model
    module FunctionSignatures
      class SignatureWithTypeAssignments
        # @param signature [Base]
        def initialize(signature)
          fail ArgumentError, method_object unless method_object.is_a?(Store::Objects::MethodObject::Connected)
          @method_object = method_object
        end
      end
    end
  end
end
