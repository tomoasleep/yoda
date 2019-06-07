module Yoda
  module HasServices
    module ClassMethods
      # Register a service with the specified name
      # @params name [String]
      def service(name, &block)
        service_hub_class.register_service(name, &block)
        define_method(:"#{name}_service") { services.public_send(name) }
      end

      # @return [Class<ServiceHub>]
      def service_hub_class
        @service_hub_class ||= Class.new(ServiceHub)
      end
    end

    class ServiceHub
      attr_reader :instance

      def initialize(instance)
        @instance = instance
      end

      def self.register_service(name, &block)
        define_method(name) do
          instance.instance_exec(instance, &block)
        end
      end
    end

    # @return [ServiceHub]
    def services
      @services ||= self.class.service_hub_class.new(self)
    end

    def self.included(klass)
      klass.extend ClassMethods
    end
  end
end
