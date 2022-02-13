require 'yaml'

module Yoda
  module Store
    class Config
      # @param yaml_str [String]
      def self.from_yaml_data(yaml_str)
        new(YAML.load(yaml_str, symbolize_names: true) || {})
      end

      # @param path [String]
      def self.at(path)
        new(YAML.load(File.read(path), symbolize_names: true) || {})
      end

      # @param contents [Hash]
      def initialize(contents)
        @contents = contents
        Logger.trace("Config: #{contents}")
      end

      # @return [Array<String>]
      def ignored_gems
        @ignored_gems ||= (@contents[:gems] || []).select { |gem_data| gem_data[:ignore] }.map { |gem_data| gem_data[:name] }
      end

      # @return [Array<String>]
      def rbs_signature_paths
        @contents.dig(:rbs, :signature) || []
      end

      # @return [Array<String>]
      def rbs_repository_paths
        @contents.dig(:rbs, :repository) || []
      end

      # @return [Array<String>]
      def rbs_libraries
        @contents.dig(:rbs, :library) || []
      end
    end
  end
end
