module Yoda
  module Model
    class Environment
      module AccessorInterface
        # @abstract
        # @return [Store::Objects::NamespaceObject::Connected, nil]
        def self_object
          fail NotImplementedError
        end

        # @abstract
        # @return [Store::Objects::NamespaceObject::Connected, nil]
        def class_object
          fail NotImplementedError
        end

        # @abstract
        # @return [RBS::Definition, nil]
        def rbs_definition
          fail NotImplementedError
        end

        # @abstract
        # @return [NamespaceMembers]
        def members
          fail NotImplementedError
        end

        # @abstract
        # @return [SingletonAccessor]
        def singleton_accessor
          fail NotImplementedError
        end

        # @abstract
        # @return [AccessorInterface, nil]
        def instance_accessor
          fail NotImplementedError
        end
      end
    end
  end
end
