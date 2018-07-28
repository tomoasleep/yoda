module Yoda
  module Commands
    class Setup < Base
      # @return [String]
      attr_reader :dir

      # @return [true, false]
      attr_reader :force_build

      # @param dir [String]
      def initialize(dir: nil, force_build: false)
        @dir = dir || Dir.pwd
        @force_build = force_build
      end

      def run
        build_core_index
        if File.exist?(File.expand_path('Gemfile.lock', dir)) || force_build
          Logger.info 'Building index for the current project...'
          force_build ? project.rebuild_cache(progress: true) : project.build_cache(progress: true)
        else
          Logger.info 'Skipped building project index because Gemfile.lock is not exist for the current dir'
        end
      end

      def project
        @project ||= Store::Project.new(dir)
      end

      private

      def build_core_index
        Store::Actions::BuildCoreIndex.run unless Store::Actions::BuildCoreIndex.exists?
      end
    end
  end
end
