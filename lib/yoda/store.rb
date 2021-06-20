require 'yard'

module Yoda
  # {Store} treats persistence and caching of code objects and querying of these objects in {Store::Registry}.
  module Store
    require 'yoda/store/actions'
    require 'yoda/store/adapters'
    require 'yoda/store/config'
    require 'yoda/store/project'
    require 'yoda/store/objects'
    require 'yoda/store/registry'
    require 'yoda/store/setup'
    require 'yoda/store/query'
    require 'yoda/store/transformers'
    require 'yoda/store/version_store'
    require 'yoda/store/yard_importer'

    class << self
      # @return [Project]
      def setup(**kwargs)
        worker = Setup.new(**kwargs)
        worker.run
        worker.project.tap(&:setup)
      end
    end
  end
end
