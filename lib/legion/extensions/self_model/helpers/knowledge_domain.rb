# frozen_string_literal: true

module Legion
  module Extensions
    module SelfModel
      module Helpers
        class KnowledgeDomain
          include Constants

          attr_reader :id, :name, :depth, :breadth, :confidence, :state, :last_accessed

          def initialize(id:, name:, depth: 0.0, breadth: 0.0)
            @id            = id
            @name          = name
            @depth         = depth.to_f.clamp(0.0, 1.0)
            @breadth       = breadth.to_f.clamp(0.0, 1.0)
            @last_accessed = nil
            @state         = compute_state
            @confidence    = average_score
          end

          def deepen(amount:)
            @depth      = (@depth + amount.to_f).clamp(0.0, 1.0)
            @state      = compute_state
            @confidence = average_score
          end

          def broaden(amount:)
            @breadth    = (@breadth + amount.to_f).clamp(0.0, 1.0)
            @state      = compute_state
            @confidence = average_score
          end

          def access!
            @last_accessed = Time.now.utc
          end

          def knowledge_label
            CONFIDENCE_LABELS.each { |range, lbl| return lbl if range.cover?(@confidence) }
            :very_low
          end

          def to_h
            {
              id:              @id,
              name:            @name,
              depth:           @depth.round(4),
              breadth:         @breadth.round(4),
              confidence:      @confidence.round(4),
              state:           @state,
              knowledge_label: knowledge_label,
              last_accessed:   @last_accessed
            }
          end

          private

          def average_score
            (@depth + @breadth) / 2.0
          end

          def compute_state
            score = average_score
            if score < 0.2
              :ignorant
            elsif score < 0.5
              :aware
            elsif score < 0.8
              :familiar
            else
              :expert
            end
          end
        end
      end
    end
  end
end
