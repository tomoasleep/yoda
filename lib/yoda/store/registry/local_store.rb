module Yoda
  module Store
    module Registry
      class LocalStore
        # @return [Proc, nil]
        attr_reader :on_change

        # @param on_change [Proc, nil]
        def initialize(on_change: nil)
          @on_change = on_change
        end

        # @return [Registry::Index::ComposerWrapper]
        def registry
          @registry ||= Registry::Index.new.wrap(Registry::Composer.new(id: :local))
        end

        # @param patch [Objects::Patch]
        def add_file_patch(patch)
          registry.add_registry(patch)
          on_change&.call
        end

        # @param patch [Objects::Patch, String, Symbol]
        def remove_file_patch(patch)
          registry.remove_registry(patch)
          on_change&.call
        end

        # @param patch [String, Symbol]
        # @return [Objects::Patch, nil]
        def find_file_patch(id)
          registry.get_registry(id)
        end
      end
    end
  end
end
