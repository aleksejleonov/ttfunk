require 'spec_helper'
require 'ttfunk/bit_field'

RSpec.describe TTFunk::BitField do
  let(:value) { 0b10100110 }
  subject { described_class.new(value) }

  describe '#on?' do
    it 'determines that the correct bits are on' do
      expect(subject.on?(0)).to eq(false)
      expect(subject.on?(1)).to eq(true)
      expect(subject.on?(2)).to eq(true)
      expect(subject.on?(3)).to eq(false)
      expect(subject.on?(4)).to eq(false)
      expect(subject.on?(5)).to eq(true)
      expect(subject.on?(6)).to eq(false)
      expect(subject.on?(7)).to eq(true)
    end
  end

  describe '#off?' do
    it 'determines that the correct bits are off' do
      expect(subject.off?(0)).to eq(true)
      expect(subject.off?(1)).to eq(false)
      expect(subject.off?(2)).to eq(false)
      expect(subject.off?(3)).to eq(true)
      expect(subject.off?(4)).to eq(true)
      expect(subject.off?(5)).to eq(false)
      expect(subject.off?(6)).to eq(true)
      expect(subject.off?(7)).to eq(false)
    end
  end

  describe '#on' do
    it 'turns the given bit on' do
      expect { subject.on(3) }.to(
        change { subject.on?(3) }.from(false).to(true)
      )
    end

    it 'updates the value' do
      expect { subject.on(0) }.to(
        change { subject.value }.from(0b10100110).to(0b10100111)
      )

      expect { subject.on(3) }.to(
        change { subject.value }.from(0b10100111).to(0b10101111)
      )
    end

    it 'does not update the value if no bits were flipped' do
      expect { subject.on(1) }.to_not(change { subject.value })
    end
  end

  describe '#off' do
    it 'turns the given bit off' do
      expect { subject.off(5) }.to(
        change { subject.off?(5) }.from(false).to(true)
      )
    end

    it 'updates the value' do
      expect { subject.off(1) }.to(
        change { subject.value }.from(0b10100110).to(0b10100100)
      )

      expect { subject.off(5) }.to(
        change { subject.value }.from(0b10100100).to(0b10000100)
      )
    end

    it 'does not update the value if no bits were flipped' do
      expect { subject.off(3) }.to_not(change { subject.value })
    end
  end
end