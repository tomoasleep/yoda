module Yoda
  module Store
    module Objects
      module ConnectedDelegation
        # @param method_names [Array<Symbol>]
        # @return [void]
        def delegate_to_object(*method_names)
          method_names.each do |method_name|
            define_method(method_name) do |*args, **kwargs|
              object.public_send(method_name, *args, **kwargs)
            end
          end
        end
      end
    end
  end
end
