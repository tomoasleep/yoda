require 'spec_helper'

RSpec.describe Yoda::Parsing::NodeObjects::ArgsNode do
  let(:node_object) { described_class.new(args_node) }

  let(:args_node) { block_node.children[1] }
  let(:block_node) { Parser::CurrentRuby.parse(source) }

  context '#parameter' do
    subject { node_object.parameter }

    context 'when parameters are given' do
      let(:source) do
        <<~EOS
        hoge { |a, b, c = 1| }
        EOS
      end

      it 'parses correctly' do
        is_expected.to have_attributes(
          parameters: [
            have_attributes(name: :a, kind: :named),
            have_attributes(name: :b, kind: :named),
            have_attributes(name: :c, kind: :named),
          ],
        )
      end
    end

    context 'when parameters and rest parameter are given' do
      let(:source) do
        <<~EOS
        hoge { |a, b, *c| }
        EOS
      end

      it 'parses correctly' do
        is_expected.to have_attributes(
          parameters: [
            have_attributes(name: :a, kind: :named),
            have_attributes(name: :b, kind: :named),
          ],
          rest_parameter: have_attributes(name: :c, kind: :named)
        )
      end
    end

    context 'when parameters, rest parameter and post parameters are given' do
      let(:source) do
        <<~EOS
        hoge { |a, b = 1, *c, d, e| }
        EOS
      end

      it 'parses correctly' do
        is_expected.to have_attributes(
          parameters: [
            have_attributes(name: :a, kind: :named),
            have_attributes(name: :b, kind: :named),
          ],
          rest_parameter: have_attributes(name: :c, kind: :named),
          post_parameters: [
            have_attributes(name: :d, kind: :named),
            have_attributes(name: :e, kind: :named),
          ]
        )
      end
    end

    context 'when parameters, rest parameter and post parameters are given' do
      let(:source) do
        <<~EOS
        hoge { |a, b:, c: nil| }
        EOS
      end

      it 'parses correctly' do
        is_expected.to have_attributes(
          parameters: [
            have_attributes(name: :a, kind: :named),
          ],
          keyword_parameters: [
            have_attributes(name: :b, kind: :named),
            have_attributes(name: :c, kind: :named),
          ]
        )
      end
    end
  end
end
