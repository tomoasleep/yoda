module Yoda
  module Store
    module Transformers
      # YARD parses some kernel methods as public.
      # This class fixes these visibilities.
      class CoreVisibility
        # @param patch [Objects::Patch]
        # @return [Objects::Patch]
        def self.transform(patch)
          new(patch).transformed_patch
        end

        # @return [Objects::Patch]
        attr_reader :patch

        # @param patch [Objects::Patch]
        def initialize(patch)
          @patch = patch
        end

        # @return [Objects::Patch]
        def transformed_patch
          @transformed_patch = begin
            if patch.has_key?(:Kernel)
              create_patch
            else
              patch
            end
          end
        end

        private

        # @return [Objects::Patch]
        def create_patch
          new_patch = Objects::Patch.new(patch.id)

          patch.keys.each do |key|
            new_patch.register(transform_object(patch.get(key)))
          end

          new_patch
        end

        # @param object [Objects::Base]
        # @return [Objects::Base]
        def transform_object(object)
          if object.kind == :method && object.namespace_path == "Kernel"
            if Kernel.private_instance_methods.include?(object.name.to_sym)
              Objects::MethodObject.new(**object.to_h, visibility: :private)
            else
              object
            end
          else
            object
          end
        end
      end
    end
  end
end
