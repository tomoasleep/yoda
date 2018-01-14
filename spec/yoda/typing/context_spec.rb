require 'spec_helper'

RSpec.describe Yoda::Typing::Context do
  include TypeHelper
  include AST::Sexp

  let(:registry) { Yoda::Store::Registry.instance }
  let(:root) { registry.at(:root) }

  let(:context) { Yoda::Typing::Context.new(registry, root) }
end
