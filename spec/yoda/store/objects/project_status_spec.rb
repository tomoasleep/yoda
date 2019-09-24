require 'spec_helper'

RSpec.xdescribe Yoda::Store::Objects::ProjectStatus do
  describe 'serialization' do
    subject { JSON.load(project_status.to_json) }
    let(:project_status) do
      Yoda::Store::Objects::ProjectStatus.new(
        version: 1,
        bundle: Yoda::Store::Objects::ProjectStatus::BundleStatus.new(
          gem_statuses: [
            Yoda::Store::Objects::ProjectStatus::GemStatus.new(
              name: 'rspec', version: '3.7.0', present: true,
            ),
            Yoda::Store::Objects::ProjectStatus::GemStatus.new(
              name: 'yard', version: '0.9.0', present: false,
            ),
          ],
          local_library_statuses: [],
          std_status: Yoda::Store::Objects::ProjectStatus::StdStatus.new(
            version: '2.5.0', core_present: true, std_present: false,
          ),
        ),
      )
    end

    it do
      is_expected.to have_attributes(
        version: 1,
        bundle: have_attributes(
          gem_statuses: contain_exactly(
            have_attributes(name: 'rspec', version: '3.7.0', present: true),
            have_attributes(name: 'yard', version: '0.9.0', present: false),
          ),
          std_status: have_attributes(version: '2.5.0', core_present: true, std_present: false),
        ),
      )
    end
  end
end
