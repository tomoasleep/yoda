module Yoda
  module Store
    module Registry
      require 'yoda/store/registry/cache'
      require 'yoda/store/registry/composer'
      require 'yoda/store/registry/index'
      require 'yoda/store/registry/library_registry'
      require 'yoda/store/registry/project_registry'

      def self.new(adapter)
        ProjectRegistry.new(adapter)
      end
    end
  end
end
