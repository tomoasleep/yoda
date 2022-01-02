require 'spec_helper'

RSpec.describe Yoda::Store::Adapters::Base do
  let(:adapter) { described_class.new }

  let(:path) { "./test" }
  let(:address) { "::String" }
  let(:object) { { a: 1 } }
  let(:data) { [address, object] }
  let(:bar) { nil }

  it "defines abstract class methods" do
    expect { described_class.for(path) }.to raise_error(NotImplementedError)
    expect { described_class.type }.to raise_error(NotImplementedError)
  end

  it "defines abstract instance methods" do
    expect { adapter.get(address) }.to raise_error(NotImplementedError)
    expect { adapter.put(address, object) }.to raise_error(NotImplementedError)
    expect { adapter.delete(address) }.to raise_error(NotImplementedError)
    expect { adapter.exist?(address) }.to raise_error(NotImplementedError)
    expect { adapter.keys }.to raise_error(NotImplementedError)
    expect { adapter.stats }.to raise_error(NotImplementedError)
    expect { adapter.sync }.to raise_error(NotImplementedError)
    expect { adapter.clear }.to raise_error(NotImplementedError)
    expect { adapter.batch_write(data, bar) }.to raise_error(NotImplementedError)
  end
end
