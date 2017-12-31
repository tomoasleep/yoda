module Yoda
  module Store
    module Types
      class UnknownType < Base
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def eql?(another)
          another.is_a?(UnknownType) &&
          name == another.name
        end

        def hash
          [self.class.name, name].hash
        end
      end
    end
  end
end
