module Yoda
  module Store
    module Objects
      module Library
        require 'yoda/store/objects/library/with_registry'
        require 'yoda/store/objects/library/core'
        require 'yoda/store/objects/library/std'
        require 'yoda/store/objects/library/gem'

        class << self
          def core
            Core.current_version
          end

          def std
            Std.current_version
          end
        end
      end
    end
  end
end
