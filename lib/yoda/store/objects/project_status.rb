module Yoda
  module Store
    module Objects
      class ProjectStatus
        include Serializable

        # @return [Integer]
        attr_reader :version

        # @return [BundleStatus]
        attr_reader :bundle

        # @param specs [Array<Bundler::LazySpecification>]
        # @return [BundleStatus]
        def self.initial_build(specs:)
          new(bundle: BundleStatus.initial_build(specs), version: Registry::REGISTRY_VERSION)
        end

        # @param bundle [BundleStatus]
        # @param version [Integer] the version number of registry
        def initialize(bundle:, version:)
          @bundle = bundle
          @version = version
        end

        def to_h
          { bundle: bundle, version: version }
        end

        # Remember gem dependencies and loaded gems
        class BundleStatus
          include Serializable

          # @return [Array<GemStatus>]
          attr_reader :gem_statuses

          # @return [StdStatus]
          attr_reader :std_status

          # @param specs [Array<Bundler::LazySpecification>]
          # @return [BundleStatus]
          def self.initial_build(specs)
            gem_statuses = specs.map { |spec| ProjectStatus::GemStatus.initial_build(spec) }
            std_status = StdStatus.initial_build
            new(gem_statuses: gem_statuses, std_status: std_status)
          end

          # @param gem_statuses [Array<GemStatus>]
          # @param std_status [StdStatus]
          def initialize(gem_statuses:, std_status:)
            @gem_statuses = gem_statuses
            @std_status = std_status
          end

          def to_h
            { gem_statuses: gem_statuses, std_status: std_status }
          end

          # @param name [String]
          # @return [GemStatus, nil]
          def [](name)
            dictionary[name]
          end

          # @return [true, false]
          def all_present?
            gem_statuses.all?(&:present?) && std_status.all_present?
          end

          # @return [Array<GemStatus>]
          def present_gems
            gem_statuses.select(&:present?)
          end

          # @return [Array<GemStatus>]
          def not_present_gems
            gem_statuses.reject(&:present?)
          end

          private

          # @return [Hash{String => GemStatus}]
          def dictionary
            @dictionary ||= gem_statuses.map do |gem_status|
              [gem_status.name, gem_status]
            end.to_h
          end
        end

        # Remember ruby core and standard library state
        class StdStatus
          include Serializable
          # @return [String]
          attr_reader :version

          # @return [true, false]
          attr_reader :core_present, :std_present

          # @return [StdStatus]
          def self.initial_build
            new(version: RUBY_VERSION, core_present: false, std_present: false)
          end

          # @param version [String]
          # @param core_present [true, false] represents the flag if core's index file is present.
          # @param std_present [true, false] represents the flag if standard library's index file is present.
          def initialize(version:, core_present:, std_present:)
            @version = version
            @core_present = core_present
            @std_present = std_present
          end

          # @return [true, false]
          def all_present?
            core_present? && std_present?
          end

          # @return [true, false]
          def core_present?
            core_present
          end

          # @return [true, false]
          def std_present?
            std_present
          end

          def to_h
            { version: version, core_present: core_present, std_present: std_present }
          end
        end

        # Remember each gem state
        class GemStatus
          include Serializable
          # @return [String]
          attr_reader :name, :version

          # @return [true, false]
          attr_reader :present

          # @param gem [Bundler::LazySpecification]
          # @return [GemStatus]
          def self.initial_build(gem)
            new(name: gem.name, version: gem.version, present: false)
          end

          # @param name [String]
          # @param version [String]
          # @param present [true, false] represents the flag if the specified gem's index file is present.
          def initialize(name:, version:, present:)
            @name = name
            @version = version
            @present = present
          end

          def to_h
            { name: name, version: version, present: present }
          end

          # @return [true, false]
          def present?
            !!present
          end
        end
      end
    end
  end
end
