module Yoda
  module Store
    module Types
      class GenericType < Base
        attr_reader :name, :type_arguments

        def initialize(name, type_arguments)
          @name = name
          @type_arguments = type_arguments
        end

        def eql?(another)
          another.is_a?(GenericType) &&
          name == another.name &&
          type_arguments == another.type_arguments
        end

        def hash
          [self.class.name, name, type_arguments].hash
        end
      end
    end
  end
end
