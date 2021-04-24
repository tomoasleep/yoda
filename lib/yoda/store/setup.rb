require "yoda/instrument"
require "ruby-progressbar"

module Yoda
  module Store
    class Setup
      # @return [String]
      attr_reader :dir

      # @return [true, false]
      attr_reader :force_build

      # @return [Hash{ Symbol => ProgressBar }]
      attr_reader :bars

      # @param dir [String]
      # @param force_build [Boolean]
      def initialize(dir:, force_build: false)
        @dir = dir
        @force_build = force_build
        @bars = {}
      end

      def run
        build_core_index
        build_project_cache
      end

      def project
        @project ||= Store::Project.new(dir)
      end

      private

      def build_project_cache
        if File.exist?(File.expand_path('Gemfile.lock', dir)) || force_build
          Logger.info 'Building index for the current project...'
          Instrument.instance.hear(initialization_progress: method(:on_progress), registry_dump: method(:on_progress)) do
            force_build ? project.reset : project.setup
          end
        else
          Logger.info 'Skipped building project index because Gemfile.lock is not exist for the current dir'
        end
      end

      def build_core_index
        Actions::BuildCoreIndex.run unless Actions::BuildCoreIndex.exists?
      end

      def on_progress(phase: :save_keys, index: nil, length: nil, **params)
        return unless index
        bar = bars[phase] ||= ProgressBar.create(format: "%t: %c/%C |%w>%i| %e ", title: phase.to_s.gsub('_', ' '), starting_at: index, total: length)
        bar.progress = index if index <= bar.total
      end
    end
  end
end
