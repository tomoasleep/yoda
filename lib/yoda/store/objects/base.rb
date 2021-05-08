require 'yoda/store/objects/connected_delegation'

module Yoda
  module Store
    module Objects
      # @abstract
      class Base
        include Addressable
        include Serializable
        include Patchable

        class << self
          # @return [Array<Symbol>]
          def attr_names
            %i(path document tag_list sources primary_source)
          end
        end

        # A wrapper class of {Objects::Base} to allow access to registry>
        class Connected
          extend ConnectedDelegation

          # @return [Base]
          attr_reader :object
          
          # @return [Registry]
          attr_reader :registry

          delegate_to_object :address, :path, :document, :tag_list, :sources, :primary_source, :json_class, :to_json, :derive
          delegate_to_object :name, :kind, :address, :parent_adderss, :to_h, :hash, :eql?, :==, :namespace?, :meta_class_address
          
          # @param object [Base]
          # @param registry [Registry]
          def initialize(object, registry:)
            @object = object
            @registry = registry
          end

          def with_connection(**kwargs)
            if kwargs == connection_options
              self
            else
              object.with_connection(**kwargs)
            end
          end

          def merge(another)
            object.merge(another).with_connection(**connection_options)
          end
          
          # @return [Objects::MetaClassObject::Connected, nil]
          def meta_class
            registry.get(meta_class_address)&.with_connection(**connection_options)
          end

          private

          # @return [Hash]
          def connection_options
            { registry: registry }
          end
        end

        # @return [String]
        attr_reader :path

        # @return [String]
        attr_reader :document

        # @return [Array<Tag>]
        attr_reader :tag_list

        # @return [Array<(String, Integer, Integer)>]
        attr_reader :sources

        # @return [(String, Integer, Integer), nil]
        attr_reader :primary_source

        # @param path [String]
        # @param document [String]
        # @param tag_list [Array<Tag>, nil]
        # @param sources [Array<(String, Integer, Integer)>]
        # @param primary_source [(String, Integer, Integer), nil]
        def initialize(path:, document: '', tag_list: [], sources: [], primary_source: nil, json_class: nil, kind: nil)
          @path = path
          @document = document
          @tag_list = tag_list
          @sources = sources
          @primary_source = primary_source
        end

        # @return [String]
        def name
          fail NotImplementedError
        end

        # @return [Symbol]
        def kind
          fail NotImplementedError
        end

        # @return [String]
        def address
          path
        end

        # @return [String]
        def meta_class_address
          MetaClassObject.address_of(address)
        end

        # @return [String]
        def parent_address
          @parent_address ||= begin
            sliced_address = address.slice(0, (path.rindex('::') || 0))
            sliced_address.empty? ? 'Object' : sliced_address
          end
        end

        # @return [Hash]
        def to_h
          {
            kind: kind,
            path: path,
            document: document,
            tag_list: tag_list,
            sources: sources,
            primary_source: primary_source,
          }
        end

        # @param another [self]
        # @return [self]
        def merge(another)
          self.class.new(**merge_attributes(another))
        end

        def hash
          ([self.class.name] + to_h.to_a).hash
        end

        def eql?(another)
          another.respond_to?(:kind) && self.kind == another.kind && to_h == another.to_h
        end

        def ==(another)
          eql?(another)
        end

        def namespace?
          false
        end

        # @return [Connected]
        def with_connection(**kwargs)
          self.class.const_get(:Connected).new(self, **kwargs)
        end

        private

        # @param another [self]
        # @return [Hash]
        def merge_attributes(another)
          {
            path: path,
            document: document + another.document,
            tag_list: tag_list + another.tag_list,
            sources: sources + another.sources,
            primary_source: primary_source || another.primary_source,
          }
        end
      end
    end
  end
end
