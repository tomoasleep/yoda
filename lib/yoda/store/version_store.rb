module Yoda
  module Store
    # Return paths for each Ruby version.
    class VersionStore
      SOURCE_PATH_BASE = File.expand_path("~/.yoda/sources")
      REGISTRY_PATH_BASE = File.expand_path('~/.yoda/registry')


      # @return [VersionStore]
      def self.for_current_version
        new(RUBY_VERSION)
      end

      attr_reader :ruby_version

      # @param version [String]
      def initialize(ruby_version)
        @ruby_version = ruby_version
      end

      # Return the path to store the version's Ruby.
      # @return [String]
      def ruby_source_path
        File.join(SOURCE_PATH_BASE, "ruby-#{ruby_version}")
      end

      # Return the path to store yard document index of the core library.
      # @return [String]
      def core_yardoc_path
        File.join(ruby_source_path, '.yardoc')
      end

      # Return the path to store yard document index of the standard library.
      # @return [String]
      def stdlib_yardoc_path
        File.join(ruby_source_path, '.yardoc-stdlib')
      end

      # Return the path to store registries.
      # @return [String]
      def registries_path
        File.join(REGISTRY_PATH_BASE, ruby_version)
      end

      # Return the path to store registry of the gem.
      # @param name [String]
      # @param version [String]
      # @return [String]
      def registry_path_for_gem(name:, version:)
        File.join(registries_path, Registry.registry_name, name, version)
      end

      # Return the path to store registry of the core library.
      # @return [String]
      def registry_path_for_core
        File.join(registries_path, Registry.registry_name, "core")
      end

      # Return the path to store registry of the standard library.
      # @return [String]
      def registry_path_for_stdlib
        File.join(registries_path, Registry.registry_name, "stdlib")
      end
    end
  end
end
