# frozen_string_literal: true

module Legion
  module Extensions
    module SelfModel
      module Helpers
        class Capability
          include Constants

          attr_reader :id, :name, :domain, :competence, :attempts, :successes, :state, :calibration_error

          def initialize(id:, name:, domain: :general, competence: DEFAULT_COMPETENCE)
            @id                = id
            @name              = name
            @domain            = domain
            @competence        = competence.to_f.clamp(COMPETENCE_FLOOR, COMPETENCE_CEILING)
            @attempts          = 0
            @successes         = 0
            @calibration_error = 0.0
            @state             = compute_state
          end

          def record_attempt(predicted_success:, actual_success:)
            @attempts += 1
            @successes += 1 if actual_success

            prediction = predicted_success ? 1.0 : 0.0
            outcome    = actual_success    ? 1.0 : 0.0

            error = prediction - outcome
            @calibration_error += CALIBRATION_ALPHA * (error - @calibration_error)

            @competence += CALIBRATION_ALPHA * (outcome - @competence)
            @competence  = @competence.clamp(COMPETENCE_FLOOR, COMPETENCE_CEILING)
            @state       = compute_state
          end

          def competence_label
            CONFIDENCE_LABELS.each { |range, lbl| return lbl if range.cover?(@competence) }
            :very_low
          end

          def calibrated?
            @calibration_error.abs < 0.15
          end

          def overconfident?
            @calibration_error > OVERCONFIDENCE_THRESHOLD
          end

          def underconfident?
            @calibration_error < UNDERCONFIDENCE_THRESHOLD
          end

          def to_h
            {
              id:                @id,
              name:              @name,
              domain:            @domain,
              competence:        @competence.round(4),
              competence_label:  competence_label,
              state:             @state,
              attempts:          @attempts,
              successes:         @successes,
              calibration_error: @calibration_error.round(4),
              calibrated:        calibrated?,
              overconfident:     overconfident?,
              underconfident:    underconfident?
            }
          end

          private

          def compute_state
            if @competence < 0.2
              :unknown
            elsif @competence < 0.5
              :developing
            elsif @competence < 0.8
              :competent
            else
              :expert
            end
          end
        end
      end
    end
  end
end
