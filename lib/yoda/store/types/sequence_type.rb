module Yoda
  module Store
    module Types
      class SequenceType < Base
        attr_reader :name, :types

        def initialize(name, types)
          @name = name
          @types = types
        end

        def eql?(another)
          another.is_a?(SequenceType) &&
          name == another.name &&
          types == another.types
        end

        def hash
          [self.class.name, name, types].hash
        end
      end
    end
  end
end
