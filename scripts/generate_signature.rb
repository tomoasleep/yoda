require 'yoda'
require 'tmpdir'

paths = Dir.glob("lib/**/*.rb").each
database_path = Dir.mktmpdir

rbs_files = Yoda::Store::Actions::RbsGenerator.new(source_dir_path: File.expand_path('../', __dir__), database_path: database_path, file_paths: paths).run

rbs_files.each do |rbs_file|
  puts rbs_file.path
  File.write(File.join("sig", rbs_file.path), rbs_file.content)
end
