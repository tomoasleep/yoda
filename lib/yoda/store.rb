require 'yard'

module Yoda
  # {Store} treats persistence and caching of code objects and querying of these objects in {Store::Registry}.
  module Store
    require 'yoda/store/actions'
    require 'yoda/store/adapters'
    require 'yoda/store/address'
    require 'yoda/store/config'
    require 'yoda/store/file_tree'
    require 'yoda/store/project'
    require 'yoda/store/objects'
    require 'yoda/store/rbs_importer'
    require 'yoda/store/registry'
    require 'yoda/store/query'
    require 'yoda/store/transformers'
    require 'yoda/store/version_store'
    require 'yoda/store/yard_importer'

    class << self
      # @return [Project]
      def setup(dir: Dir.pwd, force_build: false)
        project = Project.for_path(dir)
        project.setup(rebuild: force_build)
        project
      end
    end
  end
end
