module Yoda
  module Services
    class LoadablePathResolver
      def initialize
      end

      # @param base_paths [Array<String>]
      # @param pattern [String]
      # @return [String, nil]
      def find_loadable_path(base_paths, pattern)
        # TODO: Support absolute path
        return nil if absolute_path?(pattern)
        return nil if pattern.start_with?("~/")
        return nil if pattern.start_with?("./")
        return nil if pattern.start_with?("../")

        base_paths.each do |base_path|
          path = File.join(base_path, pattern)

          if File.extname(path).empty?
            paths_with_suffix = ::Gem.suffixes.map { |suffix| path + suffix }
            matched_path = paths_with_suffix.find { |path| File.file?(path) }
            return matched_path if matched_path
          else
            return path if File.file?(path)
          end
        end

        return nil
      end

      # This is a workaround for Ruby 2.6 (This version does not have `File.absolute_path?`)
      # @param path [String]
      # @return [Boolean]
      def absolute_path?(path)
        path[0] == "/"
      end
    end
  end
end
