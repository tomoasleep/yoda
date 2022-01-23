require 'spec_helper'

RSpec.xdescribe Yoda::Store::Objects::LibrariesStatus do
  describe 'serialization' do
    subject { JSON.load(project_status.to_json) }
    let(:project_status) do
      Yoda::Store::Objects::LibrariesStatus.new(
        version: 1,
        bundle: Yoda::Store::Objects::LibrariesStatus::BundleStatus.new(
          gem_statuses: [
            Yoda::Store::Objects::LibrariesStatus::GemStatus.new(
              name: 'rspec', version: '3.7.0', present: true,
            ),
            Yoda::Store::Objects::LibrariesStatus::GemStatus.new(
              name: 'yard', version: '0.9.0', present: false,
            ),
          ],
          local_library_statuses: [],
          std_status: Yoda::Store::Objects::LibrariesStatus::StdStatus.new(
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
