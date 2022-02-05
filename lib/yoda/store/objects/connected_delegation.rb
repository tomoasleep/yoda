module Yoda
  module Store
    module Objects
      module ConnectedDelegation
        # @param method_names [Array<Symbol>]
        # @return [void]
        def delegate_to_object(*method_names)
          if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
            method_names.each do |method_name|
              define_method(method_name) do |*args, **kwargs|
                object.public_send(method_name, *args, **kwargs)
              end
            end
          else
            method_names.each do |method_name|
              define_method(method_name) do |*args|
                object.public_send(method_name, *args)
              end
            end
          end
        end
      end
    end
  end
end
