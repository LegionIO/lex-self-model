# frozen_string_literal: true

module Legion
  module Extensions
    module SelfModel
      module Runners
        module SelfModel
          include Helpers::Constants
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def add_self_capability(name:, domain: :general, competence: DEFAULT_COMPETENCE, **)
            cap = model.add_capability(name: name, domain: domain, competence: competence)
            return { success: false, reason: :limit_reached } unless cap

            { success: true, capability_id: cap.id, competence: cap.competence.round(4), state: cap.state }
          end

          def add_self_knowledge(name:, depth: 0.0, breadth: 0.0, **)
            dom = model.add_knowledge_domain(name: name, depth: depth, breadth: breadth)
            return { success: false, reason: :limit_reached } unless dom

            { success: true, domain_id: dom.id, depth: dom.depth.round(4), breadth: dom.breadth.round(4),
              state: dom.state }
          end

          def predict_own_success(capability_id:, **)
            prediction = model.predict_success(capability_id: capability_id)
            return { success: false, reason: :not_found } unless prediction

            { success: true }.merge(prediction)
          end

          def record_self_outcome(capability_id:, predicted:, actual:, **)
            event = model.record_outcome(capability_id: capability_id, predicted: predicted, actual: actual)
            return { success: false, reason: :not_found } unless event

            cap = model.capabilities[capability_id]
            { success: true, capability_id: capability_id, competence: cap.competence.round(4),
              calibration_error: cap.calibration_error.round(4) }
          end

          def self_introspection(**)
            { success: true }.merge(model.introspect)
          end

          def self_strengths(**)
            strengths = model.strengths.map(&:to_h)
            { success: true, strengths: strengths, count: strengths.size }
          end

          def self_weaknesses(**)
            weaknesses = model.weaknesses.map(&:to_h)
            { success: true, weaknesses: weaknesses, count: weaknesses.size }
          end

          def self_blind_spots(**)
            blind_spots = model.blind_spots.map(&:to_h)
            { success: true, blind_spots: blind_spots, count: blind_spots.size }
          end

          def self_calibration_report(**)
            { success: true }.merge(model.calibration_report)
          end

          def self_model_stats(**)
            { success: true }.merge(model.to_h)
          end

          private

          def model
            @model ||= Helpers::SelfModel.new
          end
        end
      end
    end
  end
end
