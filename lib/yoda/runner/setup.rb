module Yoda
  module Runner
    class Setup
      def self.run
        new.run
      end

      def run
        project.prepare_database
      end

      def project
        @project ||= Store::Project.new(Dir.pwd)
      end
    end
  end
end
