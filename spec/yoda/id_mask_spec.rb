require 'spec_helper'

RSpec.describe Yoda::IdMask do
  let(:mask) do
    described_class.build(pattern)
  end

  describe '#cover?' do
    context 'when nil pattern is given' do
      let(:pattern) { nil }

      it 'returns true to any keys' do
        expect(mask.cover?(:hoge)).to be_truthy
        expect(mask.cover?(:fuga)).to be_truthy
        expect(mask.cover?('hoge')).to be_truthy
      end
    end

    context 'when array pattern is given' do
      let(:pattern) { [:hoge, 'key'] }

      it 'returns true to keys in the array' do
        expect(mask.cover?(:hoge)).to be_truthy
        expect(mask.cover?('hoge')).to be_truthy
        expect(mask.cover?(:fuga)).to be_falsey
        expect(mask.cover?(:key)).to be_truthy
      end
    end

    context 'when hash pattern is given' do
      let(:pattern) { { hoge: nil, key: [] } }

      it 'returns true to keys in the hash' do
        expect(mask.cover?(:hoge)).to be_truthy
        expect(mask.cover?('hoge')).to be_truthy
        expect(mask.cover?(:fuga)).to be_falsey
        expect(mask.cover?(:key)).to be_truthy
      end
    end

    context 'when id mask is given' do
      let(:pattern) { described_class.build({ hoge: nil, key: [] }) }

      it 'returns true to keys in the hash' do
        expect(mask.cover?(:hoge)).to be_truthy
        expect(mask.cover?('hoge')).to be_truthy
        expect(mask.cover?(:fuga)).to be_falsey
        expect(mask.cover?(:key)).to be_truthy
      end
    end
  end

  describe '#covering_ids' do
    subject { mask.covering_ids }

    context 'when nil pattern is given' do
      let(:pattern) { nil }

      it { is_expected.to be_nil }
    end

    context 'when array pattern is given' do
      let(:pattern) { [:hoge, 'key'] }

      it { is_expected.to contain_exactly(:hoge, :key) }
    end

    context 'when hash pattern is given' do
      let(:pattern) { { hoge: nil, key: [] } }

      it { is_expected.to contain_exactly(:hoge, :key) }
    end

    context 'when id mask is given' do
      let(:pattern) { described_class.build({ hoge: nil, key: [] }) }

      it { is_expected.to contain_exactly(:hoge, :key) }
    end
  end

  describe '#intersection' do
    subject { mask.intersection(another) }

    context 'when self is nil pattern' do
      let(:pattern) { nil }
      let(:another) { [:a] }

      it 'returns the given one' do
        expect(subject.to_pattern).to match({ a: nil })
      end
    end

    context 'when the given one is nil pattern' do
      let(:pattern) { [:b] }
      let(:another) { nil }

      it 'returns self' do
        expect(subject.to_pattern).to match({ b: nil })
      end
    end


    context 'when the both is not nil pattern' do
      let(:pattern) { { hoge: [:hoge_a], fuga: [:fuga_a, :fuga_b], poyo: [:poyo_a] } }
      let(:another) { { hoge: [:hoge_a], fuga: [:fuga_b, :fuga_c], poyo: nil, piyo: [:a] } }


      it 'returns their intersection' do
        expect(subject.to_pattern).to match({
          hoge: { hoge_a: nil },
          fuga: { fuga_b: nil },
          poyo: { poyo_a: nil },
        })
      end
    end
  end
end
