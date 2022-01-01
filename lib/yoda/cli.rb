require 'thor'

module Yoda
  # Cli module has handler for each cli command.
  module Cli
    require 'yoda/cli/base'
    require 'yoda/cli/file_cursor_parsable'
    require 'yoda/cli/infer'
    require 'yoda/cli/complete'
    require 'yoda/cli/console'

    class Top < Thor
      class_option :log_level, type: :string, desc: 'Set log level (debug info warn error fatal)'
      class_option :profile, type: :boolean, desc: 'Set log level (debug info warn error fatal)'
      class_option :help, type: :boolean, desc: 'Show help', aliases: :h,  hide: true

      desc 'setup', 'Setup indexes for current Ruby version and project gems'
      option :force_build, type: :boolean, desc: "If enabled, (re)build current project's index forcibly"
      def setup
        process_class_options
        return self.class.command_help(shell, __method__) if options[:help]
        Store.setup(dir: Dir.pwd, force_build: options[:force_build])
      end

      desc 'infer POSITION', 'Infer the type of value at the specified position'
      def infer(position)
        process_class_options
        return self.class.command_help(shell, __method__) if options[:help]
        Cli::Infer.run(position)
      end

      desc 'complete POSITION', 'Provide completion candidates for the specified position'
      def complete(position)
        process_class_options
        return self.class.command_help(shell, __method__) if options[:help]
        Cli::Complete.run(position)
      end

      desc 'console', 'Launch debug console'
      def console
        process_class_options
        return self.class.command_help(shell, __method__) if options[:help]
        Cli::Console.run
      end

      desc 'server', 'Start Language Server'
      def server
        process_class_options
        return self.class.command_help(shell, __method__) if options[:help]
        Server.new.run
      end

      desc 'version', 'show current version'
      def version
        process_class_options
        return self.class.command_help(shell, __method__) if options[:help]
        say "#{Yoda::VERSION}"
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
