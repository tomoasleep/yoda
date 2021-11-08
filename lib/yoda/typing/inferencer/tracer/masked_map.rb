module Yoda
  module Typing
    class Inferencer
      class Tracer
        class MaskedMap
          def initialize
            @content = {}
          end

          def [](key)
            @content[key]
          end

          def []=(key, value)
            @content[key] = value
          end

          def to_s
            inspect
          end

          def inspect
            "(#{@content.length} items)"
          end
        end
      end
    end
  end
end
