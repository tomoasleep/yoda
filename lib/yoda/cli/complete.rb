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
        puts create_signature_help(worker.current_node_signature)
      end

      private

      # @param signature [Model::NodeSignature, nil]
      # @return [String, nil]
      def create_signature_help(signature)
        return nil unless signature
        signature.descriptions.map(&:title).join("\n")
      end

      def worker
        @worker ||= Commands::CurrentNodeExplain.new(project.registry, File.read(filename), position)
      end

      def project
        @project ||= Store::Project.new(Dir.pwd)
      end
    end
  end
end
