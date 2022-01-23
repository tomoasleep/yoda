require 'spec_helper'

RSpec.xdescribe Yoda::Store::Actions::ImportProjectDependencies do
  let(:root_dir) { File.expand_path("../../..", __dir__) }
  let(:project) { Yoda::Store::Project.new(name: 'yoda', root_path: root_dir) }
  let(:registry) { Yoda::Store::Registry.new(adapter) }
  let(:adapter) { Yoda::Store::Adapters::MemoryAdapter.new }

  let(:loader) { described_class.new(registry: registry) }

  describe '#run' do
    subject { loader.run }

    shared_context 'mock ImportCoreLibrary action' do |response:, call_counts: 1|
      before do
        expect(class_double('Yoda::Store::Actions::ImportCoreLibrary').as_stubbed_const(transfer_nested_constants: true)).to receive(:run).and_return(response).exactly(call_counts).times
      end
    end

    shared_context 'mock ImportStdLibrary action' do |response:, call_counts: 1|
      before do
        expect(class_double('Yoda::Store::Actions::ImportStdLibrary').as_stubbed_const(transfer_nested_constants: true)).to receive(:run).and_return(response).exactly(call_counts).times
      end
    end

    shared_context 'mock ImportGem action' do |name:, version:, response:, call_counts: 1|
      before do
        stub = class_double('Yoda::Store::Actions::ImportGem').as_stubbed_const(transfer_nested_constants: true)
        expect(stub).to receive(:run).with(registry: registry, gem_name: name, gem_version: version).and_return(response)
                        .exactly(call_counts).times
      end
    end

    shared_context 'set initial status' do |core_present:, std_present:|
      before { registry.save_project_status(project_status) }
      let(:project_status) do
        Yoda::Store::Objects::LibrariesStatus.new(
          version: 1,
          bundle: Yoda::Store::Objects::LibrariesStatus::BundleStatus.new(
            gem_statuses: gem_specs,
            std_status: Yoda::Store::Objects::LibrariesStatus::StdStatus.new(
              version: '2.5.0', core_present: core_present, std_present: std_present,
            ),
          ),
        )
      end
    end

    context 'when gem_specs are empty' do
      let(:gem_specs) { [] }

      context 'when the registry is initial state' do
        include_context 'mock ImportCoreLibrary action', response: true
        include_context 'mock ImportStdLibrary action', response: true

        it 'runs ImportCoreLibrary action and ImportStdLibrary action and update statuses' do
          subject
          expect(registry.project_status.bundle.std_status).to have_attributes(core_present: true, std_present: true)
        end
      end

      context 'when the registry is already imported core' do
        include_context 'set initial status', core_present: true, std_present: false
        include_context 'mock ImportCoreLibrary action', response: true, call_counts: 0
        include_context 'mock ImportStdLibrary action', response: true

        it 'runs ImportStdLibrary action and update statuses' do
          subject
          expect(registry.project_status.bundle.std_status).to have_attributes(core_present: true, std_present: true)
        end
      end

      context 'when the registry is already imported core' do
        include_context 'set initial status', core_present: false, std_present: true
        include_context 'mock ImportCoreLibrary action', response: true
        include_context 'mock ImportStdLibrary action', response: true, call_counts: 0

        it 'runs ImportCoreLibrary action and update statuses' do
          subject
          expect(registry.project_status.bundle.std_status).to have_attributes(core_present: true, std_present: true)
        end
      end
    end

    context 'when gem_specs are not empty' do
      let(:gem_specs) do
        [
          Yoda::Store::Objects::LibrariesStatus::GemStatus.new(name: 'yard', version: '1.0.0', present: true),
          Yoda::Store::Objects::LibrariesStatus::GemStatus.new(name: 'rspec', version: '1.0.0', present: false),
        ]
      end

      include_context 'set initial status', core_present: true, std_present: true
      include_context 'mock ImportGem action', name: 'rspec', version: '1.0.0', response: true

      it 'runs ImportGem action for not imported gems and update statuses' do
        subject
        expect(registry.project_status.bundle.std_status).to have_attributes(core_present: true, std_present: true)
        expect(registry.project_status.bundle.gem_statuses).to contain_exactly(
          have_attributes(name: 'yard', version: '1.0.0', present: true),
          have_attributes(name: 'rspec', version: '1.0.0', present: true),
        )
      end
    end
  end
end
