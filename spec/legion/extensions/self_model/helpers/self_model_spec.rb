# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfModel::Helpers::SelfModel do
  subject(:sm) { described_class.new }

  describe '#initialize' do
    it 'starts with empty capabilities' do
      expect(sm.capabilities).to be_empty
    end

    it 'starts with empty knowledge domains' do
      expect(sm.knowledge_domains).to be_empty
    end

    it 'starts with empty predictions and history' do
      expect(sm.predictions).to be_empty
      expect(sm.history).to be_empty
    end
  end

  describe '#add_capability' do
    it 'adds and returns a capability' do
      cap = sm.add_capability(name: 'reasoning', domain: :cognitive)
      expect(cap).to be_a(Legion::Extensions::SelfModel::Helpers::Capability)
      expect(cap.name).to eq('reasoning')
    end

    it 'assigns unique symbol ids' do
      a = sm.add_capability(name: 'a')
      b = sm.add_capability(name: 'b')
      expect(a.id).to be_a(Symbol)
      expect(b.id).to be_a(Symbol)
      expect(a.id).not_to eq(b.id)
    end

    it 'returns nil at capacity limit' do
      Legion::Extensions::SelfModel::Helpers::Constants::MAX_CAPABILITIES.times do |i|
        sm.add_capability(name: "cap_#{i}")
      end
      expect(sm.add_capability(name: 'overflow')).to be_nil
    end
  end

  describe '#add_knowledge_domain' do
    it 'adds and returns a knowledge domain' do
      dom = sm.add_knowledge_domain(name: 'graph theory', depth: 0.6, breadth: 0.4)
      expect(dom).to be_a(Legion::Extensions::SelfModel::Helpers::KnowledgeDomain)
      expect(dom.name).to eq('graph theory')
    end

    it 'assigns unique symbol ids' do
      a = sm.add_knowledge_domain(name: 'a')
      b = sm.add_knowledge_domain(name: 'b')
      expect(a.id).to be_a(Symbol)
      expect(b.id).to be_a(Symbol)
      expect(a.id).not_to eq(b.id)
    end

    it 'returns nil at capacity limit' do
      Legion::Extensions::SelfModel::Helpers::Constants::MAX_KNOWLEDGE_DOMAINS.times do |i|
        sm.add_knowledge_domain(name: "dom_#{i}")
      end
      expect(sm.add_knowledge_domain(name: 'overflow')).to be_nil
    end
  end

  describe '#predict_success' do
    it 'returns a prediction hash for a known capability' do
      cap = sm.add_capability(name: 'analysis', competence: 0.7)
      pred = sm.predict_success(capability_id: cap.id)
      expect(pred).to include(:capability_id, :predicted_probability, :at)
      expect(pred[:predicted_probability]).to be_within(0.01).of(0.7)
    end

    it 'returns nil for unknown capability' do
      expect(sm.predict_success(capability_id: :bogus)).to be_nil
    end

    it 'logs prediction to predictions array' do
      cap = sm.add_capability(name: 'x')
      sm.predict_success(capability_id: cap.id)
      expect(sm.predictions.size).to eq(1)
    end
  end

  describe '#record_outcome' do
    it 'returns an event for a known capability' do
      cap = sm.add_capability(name: 'writing')
      event = sm.record_outcome(capability_id: cap.id, predicted: true, actual: true)
      expect(event).to include(:type, :capability_id, :predicted, :actual, :at)
    end

    it 'returns nil for unknown capability' do
      expect(sm.record_outcome(capability_id: :bogus, predicted: true, actual: false)).to be_nil
    end

    it 'updates capability competence' do
      cap = sm.add_capability(name: 'math', competence: 0.3)
      original = cap.competence
      sm.record_outcome(capability_id: cap.id, predicted: false, actual: true)
      expect(cap.competence).to be > original
    end

    it 'logs event to history' do
      cap = sm.add_capability(name: 'x')
      sm.record_outcome(capability_id: cap.id, predicted: true, actual: true)
      expect(sm.history.size).to eq(1)
    end
  end

  describe '#introspect' do
    it 'returns a complete introspection hash' do
      sm.add_capability(name: 'coding', competence: 0.85)
      sm.add_capability(name: 'guessing', competence: 0.15)
      sm.add_knowledge_domain(name: 'ruby', depth: 0.2, breadth: 0.1)

      result = sm.introspect
      expect(result).to include(:overall_confidence, :strengths, :weaknesses, :blind_spots,
                                :knowledge_gaps, :calibration)
    end
  end

  describe '#strengths' do
    it 'returns capabilities with competence > 0.7' do
      sm.add_capability(name: 'strong', competence: 0.8)
      sm.add_capability(name: 'weak', competence: 0.2)
      expect(sm.strengths.map(&:name)).to include('strong')
      expect(sm.strengths.map(&:name)).not_to include('weak')
    end
  end

  describe '#weaknesses' do
    it 'returns capabilities with competence < 0.3' do
      sm.add_capability(name: 'strong', competence: 0.8)
      sm.add_capability(name: 'weak', competence: 0.2)
      expect(sm.weaknesses.map(&:name)).to include('weak')
      expect(sm.weaknesses.map(&:name)).not_to include('strong')
    end
  end

  describe '#blind_spots' do
    it 'returns empty initially' do
      sm.add_capability(name: 'x', competence: 0.7)
      expect(sm.blind_spots).to be_empty
    end

    it 'returns capabilities that are overconfident after bad predictions' do
      cap = sm.add_capability(name: 'overestimated', competence: 0.9)
      30.times { sm.record_outcome(capability_id: cap.id, predicted: true, actual: false) }
      expect(sm.blind_spots).not_to be_empty
    end
  end

  describe '#calibration_report' do
    it 'returns uncalibrated label when no capabilities exist' do
      report = sm.calibration_report
      expect(report[:label]).to eq(:uncalibrated)
      expect(report[:total]).to eq(0)
    end

    it 'returns a label and mean_error when capabilities exist' do
      sm.add_capability(name: 'x', competence: 0.5)
      report = sm.calibration_report
      expect(report).to include(:label, :mean_error, :calibrated_count, :total)
    end
  end

  describe '#knowledge_gaps' do
    it 'returns domains with depth < 0.3' do
      sm.add_knowledge_domain(name: 'shallow', depth: 0.1, breadth: 0.5)
      sm.add_knowledge_domain(name: 'deep', depth: 0.8, breadth: 0.5)
      gaps = sm.knowledge_gaps.map(&:name)
      expect(gaps).to include('shallow')
      expect(gaps).not_to include('deep')
    end
  end

  describe '#can_do?' do
    it 'returns true for high-competence capability by name' do
      sm.add_capability(name: 'fly', competence: 0.8)
      expect(sm.can_do?('fly')).to be true
    end

    it 'returns false for low-competence capability' do
      sm.add_capability(name: 'swim', competence: 0.2)
      expect(sm.can_do?('swim')).to be false
    end

    it 'returns false for unknown capability name' do
      expect(sm.can_do?('teleport')).to be false
    end
  end

  describe '#knows_about?' do
    it 'returns true for high-confidence domain by name' do
      sm.add_knowledge_domain(name: 'physics', depth: 0.7, breadth: 0.6)
      expect(sm.knows_about?('physics')).to be true
    end

    it 'returns false for low-confidence domain' do
      sm.add_knowledge_domain(name: 'astrology', depth: 0.1, breadth: 0.1)
      expect(sm.knows_about?('astrology')).to be false
    end

    it 'returns false for unknown domain name' do
      expect(sm.knows_about?('magic')).to be false
    end
  end

  describe '#overall_confidence' do
    it 'returns DEFAULT_COMPETENCE when no capabilities exist' do
      expect(sm.overall_confidence).to eq(Legion::Extensions::SelfModel::Helpers::Constants::DEFAULT_COMPETENCE)
    end

    it 'returns average competence across capabilities' do
      sm.add_capability(name: 'a', competence: 0.4)
      sm.add_capability(name: 'b', competence: 0.6)
      expect(sm.overall_confidence).to be_within(0.01).of(0.5)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = sm.to_h
      expect(h).to include(:capability_count, :knowledge_domain_count, :overall_confidence,
                           :strength_count, :weakness_count, :blind_spot_count,
                           :knowledge_gap_count, :prediction_count, :history_size)
    end

    it 'reflects correct counts' do
      sm.add_capability(name: 'x', competence: 0.8)
      sm.add_knowledge_domain(name: 'y', depth: 0.1, breadth: 0.1)
      h = sm.to_h
      expect(h[:capability_count]).to eq(1)
      expect(h[:knowledge_domain_count]).to eq(1)
    end
  end
end
