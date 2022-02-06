module Yoda
  module Cli
    class Infer < Base
      attr_reader :filename_with_position

      # @param filename_with_position [String] position representation with the format `path/to/file:line_num:character_num`
      def initialize(filename_with_position)
        @filename_with_position = filename_with_position
      end

      def run
        project.setup
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
        @worker ||= Services::CurrentNodeExplain.from_source(registry: project.registry, source: File.read(filename), location: position)
      end

      def project
        @project ||= Store::Project.for_path(Dir.pwd)
      end

      def filename
        @filename ||= filename_with_position.split(':').first
      end

      def position
        @position ||= begin
          row, column = filename_with_position.split(':').slice(1..2)
          Parsing::Location.new(row: row.to_i, column: column.to_i)
        end
      end
    end
  end
end
