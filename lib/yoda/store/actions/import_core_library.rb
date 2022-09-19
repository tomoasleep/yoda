require 'yoda/store/actions/action_process_runner'

module Yoda
  module Store
    module Actions
      class ImportCoreLibrary
        include ActionProcessRunner::Mixin
        
        # @return [Project::Dependency::Core]
        attr_reader :dep

        class << self
          # @param (see #initialize)
          # @return (see #run)
          def run(dep)
            new(dep).run
          end

          # @param (see #initialize)
          # @return (see #run)
          def run_process(dep)
            new(dep).run_process
          end
        end

        # @param dep [Project::Dependency::Core]
        def initialize(dep)
          @dep = dep
        end

        # @return [Array<Objects::Patch>]
        def run
          RubySourceDownloader.run unless RubySourceDownloader.downloaded?

          yardoc_runner = YardocRunner.new(
            source_dir_path: VersionStore.for_current_version.ruby_source_path,
            database_path: dep.doc_path,
            file_paths: ["*.c"]
          )

          patch = yardoc_runner.run
          Transformers::CoreVisibility.transform(patch)
        end
      end
    end
  end
end
