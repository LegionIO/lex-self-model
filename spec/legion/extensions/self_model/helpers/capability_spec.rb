# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfModel::Helpers::Capability do
  subject(:cap) do
    described_class.new(id: :cap_one, name: 'write code', domain: :engineering, competence: 0.6)
  end

  describe '#initialize' do
    it 'sets id, name, domain' do
      expect(cap.id).to eq(:cap_one)
      expect(cap.name).to eq('write code')
      expect(cap.domain).to eq(:engineering)
    end

    it 'sets competence' do
      expect(cap.competence).to eq(0.6)
    end

    it 'starts with zero attempts and successes' do
      expect(cap.attempts).to eq(0)
      expect(cap.successes).to eq(0)
    end

    it 'starts with zero calibration error' do
      expect(cap.calibration_error).to eq(0.0)
    end

    it 'clamps competence to floor' do
      c = described_class.new(id: :x, name: 'x', competence: -1.0)
      expect(c.competence).to eq(Legion::Extensions::SelfModel::Helpers::Constants::COMPETENCE_FLOOR)
    end

    it 'clamps competence to ceiling' do
      c = described_class.new(id: :x, name: 'x', competence: 2.0)
      expect(c.competence).to eq(Legion::Extensions::SelfModel::Helpers::Constants::COMPETENCE_CEILING)
    end

    it 'sets initial state based on competence' do
      expect(cap.state).to eq(:competent)
    end
  end

  describe '#record_attempt' do
    it 'increments attempts' do
      cap.record_attempt(predicted_success: true, actual_success: true)
      expect(cap.attempts).to eq(1)
    end

    it 'increments successes on actual success' do
      cap.record_attempt(predicted_success: true, actual_success: true)
      expect(cap.successes).to eq(1)
    end

    it 'does not increment successes on failure' do
      cap.record_attempt(predicted_success: true, actual_success: false)
      expect(cap.successes).to eq(0)
    end

    it 'updates competence toward actual outcome' do
      original = cap.competence
      cap.record_attempt(predicted_success: true, actual_success: false)
      expect(cap.competence).to be < original
    end

    it 'updates calibration error toward prediction error' do
      cap.record_attempt(predicted_success: true, actual_success: false)
      expect(cap.calibration_error).not_to eq(0.0)
    end

    it 'keeps competence within floor/ceiling' do
      low_cap = described_class.new(id: :x, name: 'x', competence: 0.06)
      20.times { low_cap.record_attempt(predicted_success: false, actual_success: false) }
      expect(low_cap.competence).to be >= Legion::Extensions::SelfModel::Helpers::Constants::COMPETENCE_FLOOR
    end
  end

  describe '#state transitions' do
    it 'returns :unknown for competence < 0.2' do
      c = described_class.new(id: :x, name: 'x', competence: 0.1)
      expect(c.state).to eq(:unknown)
    end

    it 'returns :developing for competence 0.2-0.5' do
      c = described_class.new(id: :x, name: 'x', competence: 0.35)
      expect(c.state).to eq(:developing)
    end

    it 'returns :competent for competence 0.5-0.8' do
      expect(cap.state).to eq(:competent)
    end

    it 'returns :expert for competence >= 0.8' do
      c = described_class.new(id: :x, name: 'x', competence: 0.9)
      expect(c.state).to eq(:expert)
    end
  end

  describe '#competence_label' do
    it 'returns a symbol' do
      expect(cap.competence_label).to be_a(Symbol)
    end

    it 'returns :moderate for 0.6' do
      expect(cap.competence_label).to eq(:moderate)
    end

    it 'returns :high for 0.8' do
      c = described_class.new(id: :x, name: 'x', competence: 0.8)
      expect(c.competence_label).to eq(:high)
    end
  end

  describe '#calibrated?' do
    it 'returns true when calibration_error is within threshold' do
      expect(cap.calibrated?).to be true
    end

    it 'returns false after many overconfident predictions' do
      c = described_class.new(id: :x, name: 'x', competence: 0.9)
      20.times { c.record_attempt(predicted_success: true, actual_success: false) }
      expect(c.calibrated?).to be false
    end
  end

  describe '#overconfident?' do
    it 'returns false initially' do
      expect(cap.overconfident?).to be false
    end

    it 'returns true after sustained overconfident predictions' do
      c = described_class.new(id: :x, name: 'x', competence: 0.9)
      30.times { c.record_attempt(predicted_success: true, actual_success: false) }
      expect(c.overconfident?).to be true
    end
  end

  describe '#underconfident?' do
    it 'returns false initially' do
      expect(cap.underconfident?).to be false
    end

    it 'returns true after sustained underconfident predictions' do
      c = described_class.new(id: :x, name: 'x', competence: 0.1)
      30.times { c.record_attempt(predicted_success: false, actual_success: true) }
      expect(c.underconfident?).to be true
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = cap.to_h
      expect(h).to include(:id, :name, :domain, :competence, :state, :attempts, :successes,
                           :calibration_error, :calibrated, :overconfident, :underconfident)
    end

    it 'rounds competence to 4 decimal places' do
      expect(cap.to_h[:competence]).to eq(cap.competence.round(4))
    end
  end
end
