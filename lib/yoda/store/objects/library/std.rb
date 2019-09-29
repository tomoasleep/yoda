module Yoda
  module Store
    module Objects
      module Library
        class Std
          include WithRegistry
          include Serializable

          # @return [String]
          attr_reader :version

          # @return [Core]
          def self.current_version
            new
          end

          # @param version [String]
          def initialize(version: RUBY_VERSION)
            @version = version
          end

          def to_h
            { version: version }
          end

          def id
            name
          end

          def name
            'std'
          end

          def version
            RUBY_VERSION
          end

          def doc_path
            File.expand_path("~/.yoda/sources/ruby-#{RUBY_VERSION}/.yardoc-stdlib")
          end

          def create_patch
            Actions::ImportStdLibrary.run(self)
          end
        end
      end
    end
  end
end
