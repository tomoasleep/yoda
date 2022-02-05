module Yoda
  module Cli
    class Complete < Base
      include FileCursorParsable

      attr_reader :filename_with_position

      # @param filename_with_position [String] position representation with the format `path/to/file:line_num:character_num`
      def initialize(filename_with_position)
        @filename_with_position = filename_with_position
      end

      def run
        project.build_cache
        puts create_completions(worker.candidates)
      end

      private

      # @param completion_item [Model::CompletionItem]
      # @return [String, nil]
      def create_completions(completion_item)
        completion_item.join("\n")
      end

      def worker
        @worker ||= Services::CodeCompletion.new(project.environment, source, position)
      end

      def project
        @project ||= Store::Project.for_path(Dir.pwd)
      end

      def source
        Parsing::SourceCutter.new(File.read(filename), position).error_recovered_source
      end
    end
  end
end
