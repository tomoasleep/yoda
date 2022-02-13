module Yoda
  module Cli
    class Console < Base
      def run
        require "pry"
        project.setup
        project.pry
      end

      private

      def project
        @project ||= Store::Project.for_path(Dir.pwd)
      end
    end
  end
end
