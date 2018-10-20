require 'ruby-progressbar'

module Yoda
  module Cli
    class Setup < Base
      # @return [String]
      attr_reader :dir

      # @return [true, false]
      attr_reader :force_build

      # @return [Hash{ Symbol => ProgressBar }]
      attr_reader :bars

      # @param dir [String]
      def initialize(dir: nil, force_build: false)
        @dir = dir || Dir.pwd
        @force_build = force_build
        @bars = {}
      end

      def run
        build_core_index
        if File.exist?(File.expand_path('Gemfile.lock', dir)) || force_build
          Logger.info 'Building index for the current project...'
          Instrument.instance.hear(initialization_progress: method(:on_progress), registry_dump: method(:on_progress)) do
            force_build ? project.rebuild_cache : project.build_cache
          end
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

      def on_progress(phase: :save_keys, index: nil, length: nil, **params)
        return unless index
        bar = bars[phase] ||= ProgressBar.create(format: "%t: %c/%C |%w>%i| %e ", title: phase.to_s.gsub('_', ' '), starting_at: index, total: length)
        bar.progress = index if index <= bar.total
      end
    end
  end
end
