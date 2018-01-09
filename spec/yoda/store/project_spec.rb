require 'spec_helper'

RSpec.describe Yoda::Store::Project do
  let(:project) { described_class.new(root_path) }
  after { project.clean }
  let(:root_path) { File.expand_path('../../support/fixture', __dir__) }
end
