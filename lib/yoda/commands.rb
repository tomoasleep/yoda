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
      desc 'setup', 'Setup indexes for current Ruby version and project gems'
      option :force_build, type: :boolean, desc: "If enabled, (re)build current project's index forcibly"
      def setup
        Commands::Setup.run(force_build: options[:force_build])
      end

      desc 'infer POSITION', 'Infer the type of value at the specified position'
      def infer(position)
        Commands::Infer.run(position)
      end

      desc 'complete POSITION', 'Provide completion candidates for the specified position'
      def complete(position)
        Commands::Complete.run(position)
      end

      desc 'server', 'Start Language Server'
      def server
        Server.new.run
      end
    end
  end
end
