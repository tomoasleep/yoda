require 'spec_helper'

# RSpec.describe Yoda::Typing::Inferencer do
#   include TypeHelper
#   include AST::Sexp
#
#   let(:registry) { Yoda::Store::Registry.instance }
#   let(:root) { registry.at(:root) }
#   let(:root_value) { Yoda::Store::Values::InstanceValue.new(registry, root) }
#
#   let(:context) { Yoda::Typing::Inferencer::Context.new(registry, root_value, root_value) }
#   let(:inferencer) { described_class.new(context) }
#
#   shared_context 'load core library' do
#     Yoda::Store::Project.new(Dir.pwd).database_builder.load_core
#   end
#
#   shared_context 'load sample signature file' do
#     before do
#       YARD.parse_string <<~EOS
#         class Sig
#           # @return [Integer]
#           attr_reader :size
#
#           # @param size [Integer]
#           def initialize(size)
#             @size = size
#           end
#         end
#       EOS
#     end
#   end
#
#   describe '#infer' do
#     let(:ast) { Yoda::Parsing::Parser.new.parse(source) }
#     subject { inferencer.infer(ast) }
#
#     context 'only an integer' do
#       include_context 'load core library'
#
#       let(:source) do
#         <<~EOS
#         1
#         EOS
#       end
#
#       it 'returns the type of the method' do
#         expect(subject.first).to eq(instance_type(Yoda::Store::Path.new(root, '::Integer')))
#       end
#     end
#
#     context 'send + to an integer' do
#       include_context 'load core library'
#
#       let(:source) do
#         <<~EOS
#         1 + 1
#         EOS
#       end
#
#       it 'returns the type of the method' do
#         expect(subject.first).to eq(instance_type(Yoda::Store::Path.new(root, '::Integer')))
#       end
#     end
#   end
# end
