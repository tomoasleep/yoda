require 'spec_helper'

RSpec.describe Yoda::Store::Project do
  let(:project) { described_class.new(root_path) }
  let(:root_path) { File.expand_path('../../support/fixtures', __dir__) }

  after { project.clear }

  describe '#reset', heavy: true do
    subject { project.reset }

    it 'completes' do
      expect { subject }.not_to raise_error
    end
  end
end
