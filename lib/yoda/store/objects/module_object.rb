module Yoda
  module Store
    module Objects
      class ModuleObject < NamespaceObject
        class Connected < NamespaceObject::Connected
        end

        def kind
          :module
        end
      end
    end
  end
end
