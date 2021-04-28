module Yoda
  module Store
    module Registry
      require 'yoda/store/registry/cache'
      require 'yoda/store/registry/composer'
      require 'yoda/store/registry/index'
      require 'yoda/store/registry/library_registry'
      require 'yoda/store/registry/project_registry'

      # @note This number must be updated when breaking change is added.
      REGISTRY_VERSION = 4

      class << self
        def new(adapter)
          ProjectRegistry.new(adapter)
        end

        def registry_name
          digest = Digest::SHA256.new
          digest.update(RUBY_VERSION)
          digest.update(REGISTRY_VERSION.to_s)
          digest.update(Adapters.default_adapter_class.type.to_s)
          digest.hexdigest
        end

        # @param project [Project]
        # @param memory [Boolean]
        # @return [Registry]
        def for_project(project)
          ProjectRegistry.for_project(project)
        end
      end
    end
  end
end
