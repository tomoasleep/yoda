require 'tempfile'

module ReadSourceHelper
  module_function

  def read_source(project:, source:)
    source_path = create_tempfile(source)
    project.file_tree.open_at(source_path)
    source_path
  end

  def create_tempfile(source)
    tempfile = Tempfile.new
    tempfile.print(source)
    tempfile.close
    tempfile.open
    tempfiles.push(tempfile)
    tempfile.path
  end

  def delete_tempfiles
    tempfiles.each { |tempfile| tempfile.unlink }
    tempfiles.clear
  end

  def tempfiles
    @tempfiles ||= []
  end
end

RSpec.configure do |c|
  c.after(:each) { ReadSourceHelper.delete_tempfiles }
end
