module Yoda
  module Runner
    class SetupDeps
      def self.run
        new.run
      end

      def run
        project.create_dependency_docs
      end

      def project
        @project ||= Store::Project.new(Dir.pwd)
      end
    end
  end
end
