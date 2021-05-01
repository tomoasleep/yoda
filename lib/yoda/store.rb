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
    require 'yoda/store/version_store'
    require 'yoda/store/yard_importer'

    class << self
      def setup(**kwargs)
        Setup.new(**kwargs).run
      end
    end
  end
end
