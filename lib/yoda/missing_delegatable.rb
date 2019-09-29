module Yoda
  module MissingDelegatable
    module ClassMethods
      # @return [Symbol, nil]
      attr_reader :delegate_missing_target

      # @param target [Symbol] the delegation target if an missing method is passed.
      def delegate_missing(target)
        @delegate_missing_target = target
      end
    end

    def respond_to_missing?(method_name, include_private)
      delegate_missing_target&.respond_to?(method_name, include_private) || super
    end

    def method_missing(method_name, *args, &blk)
      if delegate_missing_target&.respond_to?(method_name)
        delegate_missing_target.public_send(method_name, *args, &blk)
      else
        super
      end
    end

    # @return [Object, nil]
    def delegate_missing_target
      self.class.delegate_missing_target && send(self.class.delegate_missing_target)
    end

    def self.included(klass)
      klass.extend(ClassMethods)
    end
  end
end
