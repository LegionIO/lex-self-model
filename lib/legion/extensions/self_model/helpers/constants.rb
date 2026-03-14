# frozen_string_literal: true

module Legion
  module Extensions
    module SelfModel
      module Helpers
        module Constants
          MAX_CAPABILITIES      = 100
          MAX_KNOWLEDGE_DOMAINS = 50
          MAX_HISTORY           = 200

          DEFAULT_COMPETENCE  = 0.5
          COMPETENCE_FLOOR    = 0.05
          COMPETENCE_CEILING  = 0.99
          CALIBRATION_ALPHA   = 0.1

          OVERCONFIDENCE_THRESHOLD  =  0.3
          UNDERCONFIDENCE_THRESHOLD = -0.3

          CAPABILITY_STATES = %i[unknown developing competent expert].freeze
          KNOWLEDGE_STATES  = %i[ignorant aware familiar expert].freeze

          CONFIDENCE_LABELS = {
            (0.9..)     => :very_high,
            (0.7...0.9) => :high,
            (0.5...0.7) => :moderate,
            (0.3...0.5) => :low,
            (..0.3)     => :very_low
          }.freeze

          CALIBRATION_LABELS = {
            excellent:    0.05,
            good:         0.10,
            fair:         0.20,
            poor:         0.35,
            uncalibrated: Float::INFINITY
          }.freeze
        end
      end
    end
  end
end
