require 'yoda/store/actions/action_process_runner'

module Yoda
  module Store
    module Actions
      class ReadFile
        include ActionProcessRunner::Mixin

        # @return [String]
        attr_reader :file

        # @return [String, nil]
        attr_reader :content

        # @return [String, nil]
        attr_reader :root_path

        # @param (see #initialize)
        # @return (see #run)
        def self.run(file, **kwargs)
          self.new(file, **kwargs).run
        end

        # @param (see #initialize)
        # @return (see #run)
        def self.run_process(file, **kwargs)
          self.new(dep, **kwargs).run_process
        end

        # @param file [String]
        # @return [String]
        def self.patch_id_for_file(file)
          YardImporter.patch_id_for_file(file)
        end

        # @param file [String]
        # @param content [String, nil]
        # @param root_path [String, nil]
        def initialize(file, content: nil, root_path: nil)
          @file = file
          @content = content
          @root_path = root_path
        end

        # @return [Array<Objects::Patch>]
        def run
          yardoc_runner.run(import_each: true)
        end

        # @param registry [Registry::ProjectRegistry]
        # @return [void]
        def run_and_register(registry)
          run.each { |patch| registry.local_store.add_file_patch(patch) }
        end

        # @param registry [Registry::ProjectRegistry]
        # @return [void]
        def run_process_and_register(registry)
          run_process.each { |patch| registry.local_store.add_file_patch(patch) }
        end

        # @return [YardocRunner]
        def yardoc_runner
          @yardoc_runner ||= if content
            YardocRunner.new(source_dir_path: root_path || Dir.pwd, contents: { file => content })
          else
            YardocRunner.new(source_dir_path: root_path || Dir.pwd, file_paths: [file])
          end
        end
      end
    end
  end
end
