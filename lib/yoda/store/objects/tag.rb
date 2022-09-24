module Yoda
  module Store
    module Objects
      class Tag
        class << self
          def json_creatable?
            true
          end

          # @param params [Hash]
          def json_create(params)
            new(**params.map { |k, v| [k.to_sym, v] }.select { |(k, v)| %i(tag_name name yard_types text lexical_scope reference_path option_key option_default).include?(k) }.to_h)
          end
        end

        # @return [String]
        attr_reader :tag_name

        # @return [String, nil]
        attr_reader :name, :text

        # @return [Array<String>]
        attr_reader :yard_types, :lexical_scope

        # @return [String, nil]
        attr_reader :option_key, :option_default

        # @return [String, nil]
        attr_reader :reference_path

        # @param tag_name   [String]
        # @param name       [String, nil]
        # @param yard_types [Array<String>]
        # @param text       [String, nil]
        # @param lexical_scope [Array<String>]
        # @param option_key [String, nil]
        # @param option_default [String, nil]
        # @param reference_path [String, nil]
        def initialize(tag_name:, name: nil, yard_types: [], text: nil, lexical_scope: [], option_key: nil, option_default: nil, reference_path: nil)
          @tag_name = tag_name
          @name = name
          @yard_types = yard_types
          @text = text
          @lexical_scope = lexical_scope
          @option_key = option_key
          @option_default = option_default
          @reference_path = reference_path
        end

        # @return [Hash]
        def to_h
          {
            name: name,
            tag_name: tag_name,
            yard_types: yard_types,
            text: text,
            lexical_scope: lexical_scope,
            option_key: option_key,
            option_default: option_default,
            reference_path: reference_path,
          }
        end

        def hash
          ([self.class.name] + to_h.to_a).hash
        end

        def kind
          :tag
        end

        def eql?(another)
          another.respond_to?(:kind) && self.kind == another.kind && to_h == another.to_h
        end

        def ==(another)
          eql?(another)
        end

        # @return [String]
        def to_json(_state = nil)
          to_h.merge(json_class: self.class.name).to_json
        end

        # @return [Array<Address>]
        def reference_address_candidates
          reference_path ?  Model::ScopedPath.new(lexical_scope, reference_path).absolute_paths.map { |path| Address.of(path) } : []
        end

        # @return [Connected]
        def with_connection(**kwargs)
          self.class.const_get(:Connected).new(self, **kwargs)
        end

        # A wrapper class of {Objects::Tag} to allow access to registry.
        class Connected
          extend ConnectedDelegation

          delegate_to_object :tag_name,
                             :name,
                             :yard_types,
                             :text,
                             :lexical_scope,
                             :option_key,
                             :option_default,
                             :reference_path,
                             :reference_address_candidates,
                             :kind,
                             :to_h,
                             :to_json,
                             :hash,
                             :eql?,
                             :==

          # @return [Tag]
          attr_reader :object

          # @return [Registry]
          attr_reader :registry

          # @param object [Tag]
          # @param registry [Registry]
          def initialize(object, registry:)
            @object = object
            @registry = registry
          end

          # @param (see ReferenceTag#with_connection)
          # @return [Connected]
          def with_connection(**kwargs)
            if kwargs == connection_options
              self
            else
              object.with_connection(**kwargs)
            end
          end

          # @return [Objects::Base, nil]
          def referring_object
            reference_address_candidates.each do |address|
              resolved = registry.get(address)&.with_connection(registry: registry)
              return resolved if resolved
            end

            nil
          end

          private

          # @return [Hash]
          def connection_options
            { registry: registry }
          end
        end
      end
    end
  end
end
