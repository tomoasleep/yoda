module Yoda
  module FileUtils
    extend self

    # @param path [String]
    # @return [Boolean]
    def writable?(path)
      return true if File.writable?(path)
      return true if !File.directory?(path) && File.writable?(File.dirname(path))
      false
    end

    # @param path [String]
    # @return [Boolean]
    def readable?(path)
      return false unless path
      return false unless File.readable?(path)
      true
    end

    # @return [String, nil]
    def yardoc_path(dep)
      return nil unless readable?(dep.full_gem_path)

      if dep.managed_by_rubygems?
        candidate = File.expand_path('.yardoc', dep.doc_dir)
        if writable?(candidate)
          candidate
        else
          dep.project.library_local_yardoc_path(name: dep.name, version: dep.version)
        end
      else
        candidate = File.expand_path('.yardoc', dep.full_gem_path)
        if writable?(candidate)
          candidate
        else
          dep.project.library_local_yardoc_path(name: dep.name, version: dep.version)
        end
      end
    end
  end
end
