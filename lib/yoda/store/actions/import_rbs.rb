require 'pathname'
require 'securerandom'

module Yoda
  module Store
    module Actions
      class ImportRbs
        # @return [String]
        attr_reader :id

        # @return [String, nil]
        attr_reader :content

        # @return [String, nil]
        attr_reader :source_path

        # @return [String, nil]
        attr_reader :root_path

        # @return [String, nil]
        attr_reader :core_root

        # @return [{ :name => String, :version => String, :path => (String, nil) }, nil]
        attr_reader :gem

        # @return [Array<Pathname, String>]
        attr_reader :dirs

        # @return [Array<RBS::Buffer>]
        attr_reader :buffers

        # # @param lockfile [RBS::Collection::Config::Lockfile]
        # # @return [Array<self>]
        # def self.multiple_for_rbs_lockfile(lockfile)
        #   runners = []

        #   runners << self.for_core

        #   repository = RBS::Repository.new(no_stdlib: true)
        #   repository.add(lockfile.full_path)
        #   runners += lockfile.gems.values.map do |gem|
        #     self.for_gem({ name: gem[:name], version: gem[:version], path: repository.lookup(gem[:name], gem[:version]) }})
        #   end

        #   runners
        # end

        # @return [self]
        def self.for_core
          self.new("core", core_root: RBS::EnvironmentLoader::DEFAULT_CORE_ROOT)
        end

        # @param gem [Objects::Library::Gem]
        # @return [self, nil]
        def self.for_gem_library(gem)
          if sig_path = gem.sig_path
            self.new(gem.sig_path, source_path: sig_path, dirs: [sig_path])
          else
            nil
          end
        end

        # @param file_name [String]
        # @param content [String]
        # @return [self]
        def self.for_file_content(file_name:, content:)
          buffer = RBS::Buffer.new(name: file_name, content: content)
          self.new(file_name || SecureRandom.hex, buffers: [buffer])
        end

        # @param file [String]
        # @return [String]
        def self.patch_id_for_file(file)
          YardImporter.patch_id_for_file(file)
        end

        # @param id [String]
        # @param content [String, nil]
        # @param root_path [String, nil]
        # @param core_root [String, nil]
        # @param gem [{ :name => String, :version => String, :path => (String, nil) }, nil]
        # @param dirs [Array<Pathname, String>]
        # @param buffers [Array<RBS::Buffer>]
        def initialize(id, source_path: nil, root_path: nil, core_root: nil, gem: nil, dirs: [], buffers: [])
          @id = id
          @source_path = source_path
          @root_path = root_path
          @core_root = core_root
          @gem = gem
          @dirs = dirs
          @buffers = buffers
        end

        # @return [Objects::Patch]
        def run
          rbs_importer = RbsImporter.new(id, source_path: source_path, root_path: root_path, environment: environment)
          rbs_importer.import
        end

        # @return [RBS::Environment]
        def environment
          @environment ||= begin
            repository = RBS::Repository.new(no_stdlib: core_root.nil?)
            loader = RBS::EnvironmentLoader.new(core_root: core_root, repository: repository)

            if gem
              loader.add(library: gem[:name], version: gem[:version], resolve_dependencies: false)
            end

            dirs.each do |dir|
              loader.add(path: Pathname(dir))
            end

            env = RBS::Environment.from_loader(loader)
            load_from_buffers(env)
            env.resolve_type_names
          end
        end

        private

        # @param env [RBS::Environment]
        # @return [void]
        def load_from_buffers(env)
          buffers.each do |buffer|
            _, directives, decls = RBS::Parser.parse_signature(buffer)

            env.add_signature(buffer: buffer, directives: directives, decls: decls)
          end
        end
      end
    end
  end
end
