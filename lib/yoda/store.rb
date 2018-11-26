require 'yard'

module Yoda
  # {Store} treats persistence and caching of code objects and querying of these objects in {Store::Registry}.
  module Store
    require 'yoda/store/actions'
    require 'yoda/store/adapters'
    require 'yoda/store/project'
    require 'yoda/store/registry_cache'
    require 'yoda/store/registry'
    require 'yoda/store/objects'
    require 'yoda/store/query'
    require 'yoda/store/yard_importer'
  end
end
