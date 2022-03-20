require 'spec_helper'
require 'fileutils'
require 'open3'

RSpec.describe Yoda::Cli::AnalyzeDeps do
  include ExecutableHelper
  include FileUriHelper

  let(:executable) { yoda_exe_path }
  let(:command) { "#{executable} analyze-deps #{project_path}" }
  let(:sample_projects_path) { File.expand_path('../../support/sample_projects', __dir__) }

  def clean_vendor_dir
    FileUtils.rm_rf(File.join(project_path, 'vendor')) if File.directory?(File.join(project_path, 'vendor'))
  end

  def execute_command
    stdout, stderr, status = Open3.capture3(command)
    unless status.success?
      fail(stderr + stdout)
    end

    stdout
  end

  subject { JSON.parse(execute_command, symbolize_names: true) }

  describe "on a project without Gemfile.lock" do
    let(:project_path) { File.join(sample_projects_path, "project_without_lock") }

    before { clean_vendor_dir }

    it "returns information about resolved gems" do
      expect(subject[:path]).to eq(project_path)
      expect(subject[:dependencies]).to including(a_hash_including(name: "activesupport", source_type: "rubygems"))
      expect(subject[:dependencies]).to including(a_hash_including(name: "minitest", source_type: "rubygems"))
    end
  end

  describe "on a project without Gemfile.lock" do
    let(:project_path) { File.join(sample_projects_path, "git_project") }

    before { clean_vendor_dir }

    it "returns information about resolved gems" do
      expect(subject[:path]).to eq(project_path)
      expect(subject[:dependencies]).to including(a_hash_including(name: "yoda-language-server", source_type: "git"))
      expect(subject[:dependencies]).to including(a_hash_including(name: "yard", source_type: "rubygems"))
    end
  end


  describe "on a project including Gemfile.lock" do
    let(:project_path) { File.join(sample_projects_path, "rails_project") }

    it "returns information about resolved gems" do
      expect(subject[:path]).to eq(project_path)
      expect(subject[:dependencies]).to including(a_hash_including(name: "rails", source_type: "rubygems"))
      expect(subject[:dependencies]).to including(a_hash_including(name: "minitest", source_type: "rubygems"))
    end
  end
end
