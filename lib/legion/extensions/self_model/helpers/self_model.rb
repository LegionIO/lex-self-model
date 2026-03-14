# frozen_string_literal: true

module Legion
  module Extensions
    module SelfModel
      module Helpers
        class SelfModel
          include Constants

          attr_reader :capabilities, :knowledge_domains, :predictions, :history

          def initialize
            @capabilities      = {}
            @knowledge_domains = {}
            @predictions       = []
            @history           = []
            @cap_counter       = 0
            @dom_counter       = 0
          end

          def add_capability(name:, domain: :general, competence: DEFAULT_COMPETENCE)
            return nil if @capabilities.size >= MAX_CAPABILITIES

            @cap_counter += 1
            cap_id = :"cap_#{@cap_counter}"
            cap = Capability.new(id: cap_id, name: name, domain: domain, competence: competence)
            @capabilities[cap_id] = cap
            cap
          end

          def add_knowledge_domain(name:, depth: 0.0, breadth: 0.0)
            return nil if @knowledge_domains.size >= MAX_KNOWLEDGE_DOMAINS

            @dom_counter += 1
            dom_id = :"dom_#{@dom_counter}"
            dom = KnowledgeDomain.new(id: dom_id, name: name, depth: depth, breadth: breadth)
            @knowledge_domains[dom_id] = dom
            dom
          end

          def predict_success(capability_id:)
            cap = @capabilities[capability_id]
            return nil unless cap

            prediction = { capability_id: capability_id, predicted_probability: cap.competence.round(4),
                           at: Time.now.utc }
            @predictions << prediction
            @predictions.shift while @predictions.size > MAX_HISTORY
            prediction
          end

          def record_outcome(capability_id:, predicted:, actual:)
            cap = @capabilities[capability_id]
            return nil unless cap

            cap.record_attempt(predicted_success: predicted, actual_success: actual)
            event = { type: :outcome, capability_id: capability_id, predicted: predicted,
                      actual: actual, at: Time.now.utc }
            @history << event
            @history.shift while @history.size > MAX_HISTORY
            event
          end

          def introspect
            {
              overall_confidence: overall_confidence.round(4),
              strengths:          strengths.map(&:to_h),
              weaknesses:         weaknesses.map(&:to_h),
              blind_spots:        blind_spots.map(&:to_h),
              knowledge_gaps:     knowledge_gaps.map(&:to_h),
              calibration:        calibration_report
            }
          end

          def strengths
            @capabilities.values.select { |c| c.competence > 0.7 }
          end

          def weaknesses
            @capabilities.values.select { |c| c.competence < 0.3 }
          end

          def blind_spots
            @capabilities.values.select(&:overconfident?)
          end

          def calibration_report
            caps = @capabilities.values
            return { label: :uncalibrated, mean_error: 0.0, calibrated_count: 0, total: 0 } if caps.empty?

            errors = caps.map { |c| c.calibration_error.abs }
            mean_error = errors.sum / errors.size.to_f
            calibrated_count = caps.count(&:calibrated?)

            label = CALIBRATION_LABELS.each do |lbl, threshold|
              break lbl if mean_error <= threshold
            end
            label = :uncalibrated unless label.is_a?(Symbol)

            { label: label, mean_error: mean_error.round(4), calibrated_count: calibrated_count,
              total: caps.size }
          end

          def knowledge_gaps
            @knowledge_domains.values.select { |d| d.depth < 0.3 }
          end

          def can_do?(capability_name)
            cap = @capabilities.values.find { |c| c.name == capability_name }
            return false unless cap

            cap.competence >= 0.5
          end

          def knows_about?(domain_name)
            dom = @knowledge_domains.values.find { |d| d.name == domain_name }
            return false unless dom

            dom.confidence >= 0.5
          end

          def overall_confidence
            return DEFAULT_COMPETENCE if @capabilities.empty?

            total = @capabilities.values.sum(&:competence)
            total / @capabilities.size.to_f
          end

          def to_h
            {
              capability_count:       @capabilities.size,
              knowledge_domain_count: @knowledge_domains.size,
              overall_confidence:     overall_confidence.round(4),
              strength_count:         strengths.size,
              weakness_count:         weaknesses.size,
              blind_spot_count:       blind_spots.size,
              knowledge_gap_count:    knowledge_gaps.size,
              prediction_count:       @predictions.size,
              history_size:           @history.size
            }
          end
        end
      end
    end
  end
end
