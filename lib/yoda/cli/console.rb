module Yoda
  module Cli
    class Console < Base
      def run
        project.build_cache
        require "pry"
        project.pry
      end

      private

      def project
        @project ||= Store::Project.new(name: 'root', root_path: Dir.pwd)
      end
    end
  end
end
