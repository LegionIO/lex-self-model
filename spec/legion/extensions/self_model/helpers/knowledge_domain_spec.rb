# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfModel::Helpers::KnowledgeDomain do
  subject(:dom) do
    described_class.new(id: :dom_one, name: 'machine learning', depth: 0.4, breadth: 0.3)
  end

  describe '#initialize' do
    it 'sets id and name' do
      expect(dom.id).to eq(:dom_one)
      expect(dom.name).to eq('machine learning')
    end

    it 'sets depth and breadth' do
      expect(dom.depth).to be_within(0.001).of(0.4)
      expect(dom.breadth).to be_within(0.001).of(0.3)
    end

    it 'computes confidence as average of depth and breadth' do
      expect(dom.confidence).to be_within(0.001).of(0.35)
    end

    it 'starts with nil last_accessed' do
      expect(dom.last_accessed).to be_nil
    end

    it 'clamps depth to 0-1' do
      d = described_class.new(id: :x, name: 'x', depth: 2.0, breadth: 0.0)
      expect(d.depth).to eq(1.0)
    end

    it 'clamps breadth to 0-1' do
      d = described_class.new(id: :x, name: 'x', depth: 0.0, breadth: -0.5)
      expect(d.breadth).to eq(0.0)
    end
  end

  describe '#deepen' do
    it 'increases depth' do
      original = dom.depth
      dom.deepen(amount: 0.2)
      expect(dom.depth).to be > original
    end

    it 'updates confidence after deepening' do
      original = dom.confidence
      dom.deepen(amount: 0.3)
      expect(dom.confidence).to be > original
    end

    it 'clamps depth at 1.0' do
      dom.deepen(amount: 5.0)
      expect(dom.depth).to eq(1.0)
    end

    it 'updates state after deepening' do
      d = described_class.new(id: :x, name: 'x', depth: 0.0, breadth: 0.0)
      d.deepen(amount: 0.9)
      expect(d.state).not_to eq(:ignorant)
    end
  end

  describe '#broaden' do
    it 'increases breadth' do
      original = dom.breadth
      dom.broaden(amount: 0.2)
      expect(dom.breadth).to be > original
    end

    it 'updates confidence after broadening' do
      original = dom.confidence
      dom.broaden(amount: 0.3)
      expect(dom.confidence).to be > original
    end

    it 'clamps breadth at 1.0' do
      dom.broaden(amount: 5.0)
      expect(dom.breadth).to eq(1.0)
    end
  end

  describe '#access!' do
    it 'sets last_accessed to current time' do
      dom.access!
      expect(dom.last_accessed).not_to be_nil
      expect(dom.last_accessed).to be_a(Time)
    end
  end

  describe '#state' do
    it 'returns :ignorant for very low scores' do
      d = described_class.new(id: :x, name: 'x', depth: 0.05, breadth: 0.05)
      expect(d.state).to eq(:ignorant)
    end

    it 'returns :aware for low scores' do
      d = described_class.new(id: :x, name: 'x', depth: 0.3, breadth: 0.3)
      expect(d.state).to eq(:aware)
    end

    it 'returns :familiar for moderate scores' do
      expect(dom.state).to eq(:aware)
    end

    it 'returns :expert for high scores' do
      d = described_class.new(id: :x, name: 'x', depth: 0.9, breadth: 0.9)
      expect(d.state).to eq(:expert)
    end
  end

  describe '#knowledge_label' do
    it 'returns a symbol' do
      expect(dom.knowledge_label).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = dom.to_h
      expect(h).to include(:id, :name, :depth, :breadth, :confidence, :state, :knowledge_label, :last_accessed)
    end

    it 'rounds depth and breadth' do
      expect(dom.to_h[:depth]).to eq(dom.depth.round(4))
      expect(dom.to_h[:breadth]).to eq(dom.breadth.round(4))
    end
  end
end
