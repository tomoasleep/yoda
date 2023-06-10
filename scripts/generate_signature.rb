require 'yoda'
require 'tmpdir'
require 'fileutils'
require 'set'

paths = Dir.glob("lib/**/*.rb")
database_path = Dir.mktmpdir
FileUtils.mkdir_p("sig")

rbs_files = Yoda::Store::Actions::RbsGenerator.new(source_dir_path: File.expand_path('../', __dir__), database_path: database_path, file_paths: paths).run(import_each: true)

sig_paths_left = Set.new(Dir.glob("sig/**/*.rbs"))

rbs_files.each do |rbs_file|
  rbs_path = File.join("sig", rbs_file.path) + "s"
  sig_paths_left.delete(rbs_path)
  puts rbs_path
  FileUtils.mkdir_p(File.dirname(rbs_path))
  File.write(rbs_path, rbs_file.content)
end

FileUtils.rm(sig_paths_left.to_a)
