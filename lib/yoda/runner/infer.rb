module Yoda
  module Runner
    class Infer
      attr_reader :filename_with_position

      def self.run(filename_with_position)
        new(filename_with_position).run
      end

      def initialize(filename_with_position)
        @filename_with_position = filename_with_position
      end

      def run
        project.setup
        puts create_signature_help(method_analyzer.calculate_current_node_type)
      end

      def method_analyzer
        @method_analyzer ||= Parsing::MethodAnalyzer.from_source(project.registry, File.read(filename), position)
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

      # @param current_type [Store::Types::Base]
      # @param range        [Parsing::Range, nil]
      def create_signature_help(type)
        type.resolve(project.registry).map { |code_object| create_hover_text(code_object) }
      end

      # @param code_object [YARD::CodeObjects::Base, YARD::CodeObjects::Proxy]
      # @return [String]
      def create_hover_text(code_object)
        if code_object.type == :proxy
          "#{code_object.path}"
        else
          "#{code_object.path} #{code_object.signature}"
        end
      end
    end
  end
end
