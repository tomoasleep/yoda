require 'yaml'

module Yoda
  module Store
    class Config
      class << self
        # @param yaml_str [String]
        def from_yaml_data(yaml_str)
          new(YAML.load(yaml_str, symbolize_names: true) || {})
        end

        def from_client_configuration(hash)
          hash = deep_symbolize_keys(hash)
          new(hash[:yoda] || {})
        end

        # @param path [String]
        def at(path)
          new(YAML.load(File.read(path), symbolize_names: true) || {})
        end

        private

        def deep_symbolize_keys(hash)
          hash.to_h do |key, value|
            value = deep_symbolize_keys(value) if value.is_a?(Hash)
            [key.to_sym, value]
          end
        end
      end

      # @return [Hash]
      attr_reader :contents

      # @param contents [Hash]
      def initialize(contents)
        @contents = contents
        Logger.trace("Config: #{contents}")
      end

      # @return [Config]
      def merge(another)
        Config.new(deep_merge(contents, another.contents))
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

      def diagnose_types?
        contents.dig(:diagnostics, :types) ? contents.dig(:diagnostics, :types) : false
      end

      private

      # @param hash1 [Hash]
      # @param hash2 [Hash]
      # @return [Hash]
      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |_, v1, v2|
          if v1.is_a?(Hash) && v2.is_a?(Hash)
            deep_merge(v1, v2)
          else
            v2
          end
        end
      end
    end
  end
end
