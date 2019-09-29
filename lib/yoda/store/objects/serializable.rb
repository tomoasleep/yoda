module Yoda
  module Store
    module Objects
      module Serializable
        module ClassMethods
          def json_creatable?
            true
          end

          # @param params [Hash]
          def json_create(params)
            new(params.reject { |k, _v| k.to_sym == :json_class }.map { |k, v| [k.to_sym, v] }.to_h)
          end
        end

        def self.included(klass)
          klass.extend(ClassMethods)
        end

        # @abstract
        # @return [Hash]
        def to_h
          fail NotImplementedError
        end

        # @return [String]
        def to_json(*options)
          to_h.merge(json_class: self.class.name).to_json
        end

        # Create a new instance which has the original parameters and overrided parameters.
        # @param params [Hash{Symbol => Object}] parameters to override
        def derive(params = {})
          self.class.new(to_h.merge(params))
        end

        def eql?(another)
          return false unless self.class.name == another.class.name
          to_h.eql?(another.to_h)
        end
      end
    end
  end
end
