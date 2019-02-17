module Yoda
  module Model
    module NodeSignatures
      class Node < Base
        def descriptions
          [node_type_description, *type_descriptions]
        end
      end
    end
  end
end
