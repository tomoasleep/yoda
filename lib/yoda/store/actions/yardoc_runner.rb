require 'tempfile'

module Yoda
  module Store
    module Actions
      class YardocRunner
        # @return [String, nil]
        attr_reader :id

        # @return [String, nil]
        attr_reader :source_dir_path, :database_path

        # @return [Array<String>]
        attr_reader :file_paths

        # @return [Hash{String => String}]
        attr_reader :contents

        # @param source_dir_path [String]
        # @param contents [Hash{String => String}]
        # @param file_paths [Array<String>]
        # @param database_path [String]
        # @apram additional_options [Array<String>]
        def initialize(source_dir_path:, contents: {}, file_paths: [], database_path: nil, id: nil)
          @source_dir_path = source_dir_path
          @file_paths = file_paths
          @contents = contents
          @database_path = database_path
          @id = id
        end

        # @param import_each [Boolean]
        # @return [Array<Objects::Patch>]
        def run(import_each: false)
          patches = []

          Dir.chdir(source_dir_path) do
            prepare_dummy_file do |dummy_paths|
              YARD::Registry.clear

              if import_each
                YARD::CLI::Yardoc.run(*build_yard_options, *dummy_paths)

                patches << import(id || YardImporter.patch_id_for_file(source_dir_path)) unless file_specified?

                file_paths.each do |file_path|
                  YARD::Registry.clear
                  YARD.parse([file_path])
                  patches << import(YardImporter.patch_id_for_file(file_path))
                end

                contents.each do |(key, content)|
                  YARD::Registry.clear
                  YARD.parse_string(content) if Yoda::Parsing.parse_with_comments(content)
                  patches << import(YardImporter.patch_id_for_file(key))
                end
              else
                YARD::CLI::Yardoc.run(*build_yard_options, *dummy_paths, *file_paths)

                contents.each do |(key, content)|
                  YARD.parse_string(content) if Yoda::Parsing.parse_with_comments(content)
                end

                patches << import(id || YardImporter.patch_id_for_file(source_dir_path))
              end
            end
          end

          patches
        end

        private

        # @param patch_id [String] patch id to generate.
        # @return [Objects::Patch]
        def import(patch_id)
          YardImporter.new(patch_id, root_path: source_dir_path, source_path: contents.keys.first).import(YARD::Registry.all + [YARD::Registry.root]).patch
        end

        # @return [Boolean]
        def file_specified?
          !file_paths.empty? || !contents.empty?
        end

        # Prepare dummy file for yardoc command not to parse any file.
        # @yield [files]
        # @yieldparam files [Array<String>] 
        def prepare_dummy_file
          if file_specified?
            Tempfile.create(["yard-tmp", ".rb"]) do |file|
              yield([file.path])
            end
          else
            yield([])
          end
        end

        # @return [Array<String>]
        def default_options
          ["--no-stats", "--no-progress", "--no-output", "--use-cache"]
        end

        # @return [Array<String>]
        def build_yard_options
          options = default_options
          if database_path
            options << "--db" << database_path
          else
            options << "--no-save"
          end
          options
        end
      end
    end
  end
end
