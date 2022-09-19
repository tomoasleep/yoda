require 'spec_helper'

RSpec.describe Yoda::Store::Project, fork: true do
  include SampleProjectsHelper

  let(:project) { described_class.for_path(root_path) }
  after { project.clear }

  describe '#reset', heavy: true do
    subject { project.reset }

    let(:root_path) { File.expand_path('../../support/fixtures', __dir__) }

    it 'completes' do
      expect { subject }.not_to raise_error
    end
  end

  describe '#setup' do
    context "activesupport_project" do
      let(:root_path) { sample_project_root('activesupport_project') }

      it "setups project dependencies" do
        project.setup
        expect(project.registry.get("ActiveSupport::Executor")).to have_attributes(kind: :class)
      end

      it "can setup twice" do
        project.setup
        project.setup
        expect(project.registry.get("ActiveSupport::Executor")).to have_attributes(kind: :class)
      end
    end

    context "yard_project" do
      let(:root_path) { sample_project_root('yard_project') }

      it "setups project dependencies" do
        project.setup
        expect(project.registry.get("YARD::CLI::CommandParser")).to have_attributes(kind: :class)
      end

      it "can setup twice" do
        project.setup
        project.setup
        expect(project.registry.get("YARD::CLI::CommandParser")).to have_attributes(kind: :class)
      end
    end
  end
end
