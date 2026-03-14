# lex-self-model

Metacognitive self-model for LegionIO cognitive agents. Tracks capability competence and knowledge domain depth with calibration error detection.

## What It Does

`lex-self-model` gives a LegionIO agent the ability to model its own competence. For each named capability (a task the agent can attempt), it tracks:

- **Competence**: running EMA score updated with each actual outcome
- **Calibration error**: how well the agent's predictions of its own success match reality
- **State**: one of `:unknown`, `:developing`, `:competent`, `:expert`

It also tracks **knowledge domains** on two axes — depth (how deep the expertise goes) and breadth (how wide the coverage is).

Introspection methods expose:
- Strengths (competence > 0.7)
- Weaknesses (competence < 0.3)
- Blind spots (overconfident capabilities — predicted success much higher than actual)
- Knowledge gaps (domains with low depth)
- Overall calibration quality

## Usage

```ruby
require 'legion/extensions/self_model'

client = Legion::Extensions::SelfModel::Client.new

# Register a capability
result = client.add_self_capability(name: 'code_review', domain: :engineering)
cap_id = result[:capability_id]
# => :cap_1

# Predict your own success on a task
client.predict_own_success(capability_id: cap_id)
# => { predicted_probability: 0.5, ... }

# Record what actually happened
client.record_self_outcome(capability_id: cap_id, predicted: true, actual: false)
# calibration_error increases — agent was overconfident

# Get a full self-assessment
client.self_introspection
# => { overall_confidence:, strengths:, weaknesses:, blind_spots:, knowledge_gaps:, calibration: }

# Add a knowledge domain
client.add_self_knowledge(name: 'distributed_systems', depth: 0.2, breadth: 0.4)

# Check capability
client.self_model_stats
# => { capability_count:, knowledge_domain_count:, overall_confidence:, ... }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
