require 'spec_helper'

RSpec.describe Yoda::Store::Registry do 
  let(:registry) { Yoda::Store::Registry.new(adapter) }
  let(:adapter) { Yoda::Store::Adapters::MemoryAdapter.new }
end
