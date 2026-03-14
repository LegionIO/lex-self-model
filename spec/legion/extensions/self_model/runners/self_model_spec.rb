# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfModel::Runners::SelfModel do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#add_self_capability' do
    it 'adds a capability and returns success' do
      result = runner.add_self_capability(name: 'planning', domain: :cognitive)
      expect(result[:success]).to be true
      expect(result[:capability_id]).to be_a(Symbol)
      expect(result[:state]).to be_a(Symbol)
    end

    it 'returns failure when limit is reached' do
      Legion::Extensions::SelfModel::Helpers::Constants::MAX_CAPABILITIES.times do |i|
        runner.add_self_capability(name: "cap_#{i}")
      end
      result = runner.add_self_capability(name: 'overflow')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_reached)
    end
  end

  describe '#add_self_knowledge' do
    it 'adds a knowledge domain and returns success' do
      result = runner.add_self_knowledge(name: 'topology', depth: 0.4, breadth: 0.3)
      expect(result[:success]).to be true
      expect(result[:domain_id]).to be_a(Symbol)
    end

    it 'returns failure when limit is reached' do
      Legion::Extensions::SelfModel::Helpers::Constants::MAX_KNOWLEDGE_DOMAINS.times do |i|
        runner.add_self_knowledge(name: "dom_#{i}")
      end
      result = runner.add_self_knowledge(name: 'overflow')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_reached)
    end
  end

  describe '#predict_own_success' do
    it 'returns prediction for known capability' do
      added = runner.add_self_capability(name: 'analysis', competence: 0.75)
      result = runner.predict_own_success(capability_id: added[:capability_id])
      expect(result[:success]).to be true
      expect(result[:predicted_probability]).to be_a(Float)
    end

    it 'returns failure for unknown capability' do
      result = runner.predict_own_success(capability_id: :nonexistent)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#record_self_outcome' do
    it 'records outcome and returns updated competence' do
      added = runner.add_self_capability(name: 'writing', competence: 0.5)
      result = runner.record_self_outcome(
        capability_id: added[:capability_id], predicted: true, actual: true
      )
      expect(result[:success]).to be true
      expect(result[:competence]).to be_a(Float)
      expect(result[:calibration_error]).to be_a(Float)
    end

    it 'returns failure for unknown capability' do
      result = runner.record_self_outcome(capability_id: :bogus, predicted: true, actual: false)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#self_introspection' do
    it 'returns introspection hash' do
      runner.add_self_capability(name: 'planning', competence: 0.8)
      result = runner.self_introspection
      expect(result[:success]).to be true
      expect(result).to include(:overall_confidence, :strengths, :weaknesses, :blind_spots)
    end
  end

  describe '#self_strengths' do
    it 'returns strengths list' do
      runner.add_self_capability(name: 'strong', competence: 0.9)
      result = runner.self_strengths
      expect(result[:success]).to be true
      expect(result[:strengths]).to be_an(Array)
      expect(result[:count]).to eq(1)
    end

    it 'returns empty list when no strengths' do
      runner.add_self_capability(name: 'weak', competence: 0.2)
      result = runner.self_strengths
      expect(result[:count]).to eq(0)
    end
  end

  describe '#self_weaknesses' do
    it 'returns weaknesses list' do
      runner.add_self_capability(name: 'weak', competence: 0.1)
      result = runner.self_weaknesses
      expect(result[:success]).to be true
      expect(result[:weaknesses]).to be_an(Array)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#self_blind_spots' do
    it 'returns empty list initially' do
      runner.add_self_capability(name: 'x', competence: 0.7)
      result = runner.self_blind_spots
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end
  end

  describe '#self_calibration_report' do
    it 'returns calibration report' do
      result = runner.self_calibration_report
      expect(result[:success]).to be true
      expect(result).to include(:label, :mean_error)
    end
  end

  describe '#self_model_stats' do
    it 'returns stats hash' do
      result = runner.self_model_stats
      expect(result[:success]).to be true
      expect(result).to include(:capability_count, :knowledge_domain_count)
    end

    it 'reflects added capabilities' do
      runner.add_self_capability(name: 'x')
      result = runner.self_model_stats
      expect(result[:capability_count]).to eq(1)
    end
  end
end
