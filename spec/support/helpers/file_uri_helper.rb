module FileUriHelper
  def file_uri(path)
    "file://#{File.expand_path(path, fixture_root)}"
  end

  def fixture_root_uri
    file_uri(fixture_root)
  end

  def fixture_root
    File.expand_path('../fixtures', __dir__)
  end
end
