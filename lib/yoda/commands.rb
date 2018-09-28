require 'thor'

module Yoda
  # Commands module has handler for each cli command.
  module Commands
    require 'yoda/commands/base'
    require 'yoda/commands/file_cursor_parsable'
    require 'yoda/commands/setup'
    require 'yoda/commands/infer'
    require 'yoda/commands/complete'

    class Top < Thor
      class_option :log_level, type: :string, desc: 'Set log level (debug info warn error fatal)'
      class_option :profile, type: :boolean, desc: 'Set log level (debug info warn error fatal)'

      desc 'setup', 'Setup indexes for current Ruby version and project gems'
      option :force_build, type: :boolean, desc: "If enabled, (re)build current project's index forcibly"
      def setup
        process_class_options
        Commands::Setup.run(force_build: options[:force_build])
      end

      desc 'infer POSITION', 'Infer the type of value at the specified position'
      def infer(position)
        process_class_options
        Commands::Infer.run(position)
      end

      desc 'complete POSITION', 'Provide completion candidates for the specified position'
      def complete(position)
        process_class_options
        Commands::Complete.run(position)
      end

      desc 'server', 'Start Language Server'
      def server
        process_class_options
        Server.new.run
      end

      private

      def process_class_options
        set_log_level
        use_profiler_if_enabled
      end

      def set_log_level
        Yoda::Logger.log_level = options[:log_level].to_sym if options[:log_level]
      end

      def use_profiler_if_enabled
        if options[:profile]
          require 'stackprof'
          require 'securerandom'
          Logger.info('Enabled profiler')
          StackProf.start(mode: :wall, raw: true)

          at_exit do
            StackProf.stop
            tmpfile_path = File.expand_path(SecureRandom.hex(12), Dir.tmpdir)
            StackProf.results(tmpfile_path)
            Logger.fatal("Dumped file to: #{tmpfile_path}")
          end
        end
      end
    end
  end
end
