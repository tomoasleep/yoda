require 'spec_helper'
require 'securerandom'

RSpec.describe Yoda::Store::Adapters::GdbmAdapter, db: :gdbm do
  include TmpdirHelper

  let(:adapter) { described_class.for(adapter_path) }
  let(:adapter_path) { File.join(tmpdir, SecureRandom.hex(10)) }
  let(:namespace) { adapter.namespace(namespace_name) }
  let(:namespace_name) { SecureRandom.hex(10) }

  describe '.for' do
    subject { described_class.for(for_parameter) }

    context 'when there is a adapter' do
      before { adapter }

      context 'and the given path is the same path' do
        let(:for_parameter) { adapter_path }

        it { is_expected.to be(adapter) }
      end

      context 'and the given path is not the same path' do
        let(:for_parameter) { File.join(tmpdir, SecureRandom.hex(12)) }
        it { is_expected.not_to be(adapter) }
      end
    end
  end

  describe '#get' do
    subject { adapter.get(object_path) }
    let(:object_path) { SecureRandom.hex(10) }

    context 'when an object is set for the path' do
      before { adapter.put(object_path, object) }
      let(:object) { { a: 1 } }

      it 'returns the object' do
        is_expected.to eq("a" => 1)
      end
    end

    context 'when an object is not set for the path' do
      it { is_expected.to be_nil }
    end

    context 'when using namespace' do
      subject { namespace.get(object_path) }

      context 'when an object is set for the path' do
        before { namespace.put(object_path, object) }
        let(:object) { { a: 1 } }

        it 'returns the object' do
          is_expected.to eq("a" => 1)
        end
      end

      context 'when an object is not set for the path' do
        it { is_expected.to be_nil }
      end
    end
  end

  describe '#clear' do
    subject { adapter.clear }

    before { adapter.put(object_path, object) }
    let(:object) { { a: 1 } }
    let(:object_path) { SecureRandom.hex(10) }

    it 'clear set objects' do
      expect { subject }.to change { adapter.get(object_path) }.from(be_truthy).to(be_falsy)
    end
  end
end
