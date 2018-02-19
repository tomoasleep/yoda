module Yoda
  module Runner
    class Infer
      attr_reader :filename_with_position

      # @param filename_with_position [String]
      def self.run(filename_with_position)
        new(filename_with_position).run
      end

      # @param filename_with_position [String]
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
        @worker ||= Evaluation::CurrentNodeExplain.new(project.registry, File.read(filename), position)
      end

      def project
        @project ||= Store::Project.new(Dir.pwd)
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
