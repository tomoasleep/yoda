module SampleProjectsHelper
  def sample_project_root(name)
    File.join(File.expand_path('../sample_projects', __dir__), name)
  end
end
