module Yoda
  module Cli
    class Console < Base
      def run
        project.setup
        require "pry"
        project.pry
      end

      private

      def project
        @project ||= Store::Project.for_path(Dir.pwd)
      end
    end
  end
end
