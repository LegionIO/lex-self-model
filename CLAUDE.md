# lex-self-model

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-self-model`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::SelfModel`

## Purpose

Metacognitive self-model — tracks the agent's own capabilities and knowledge domains with calibrated confidence. The agent registers capabilities (named tasks it can attempt), records actual outcomes, and receives running EMA-based competence scores with calibration error tracking. Supports introspection: strengths, weaknesses, blind spots (overconfident capabilities), and knowledge gaps.

## Gem Info

- **Gem name**: `lex-self-model`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/self_model/
  version.rb                        # VERSION = '0.1.0'
  helpers/
    constants.rb                    # limits, competence bounds, thresholds, label maps
    capability.rb                   # Capability class — single skill with EMA competence tracking
    knowledge_domain.rb             # KnowledgeDomain class — depth + breadth knowledge model
    self_model.rb                   # SelfModel class — container for capabilities and domains
  runners/
    self_model.rb                   # Runners::SelfModel module — all public runner methods
  client.rb                         # Client class including Runners::SelfModel
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `MAX_CAPABILITIES` | 100 | Maximum tracked capabilities |
| `MAX_KNOWLEDGE_DOMAINS` | 50 | Maximum tracked knowledge domains |
| `MAX_HISTORY` | 200 | Maximum prediction/outcome history entries |
| `DEFAULT_COMPETENCE` | 0.5 | Starting competence for new capabilities |
| `COMPETENCE_FLOOR` | 0.05 | Minimum competence value |
| `COMPETENCE_CEILING` | 0.99 | Maximum competence value |
| `CALIBRATION_ALPHA` | 0.1 | EMA alpha for competence and calibration error updates |
| `OVERCONFIDENCE_THRESHOLD` | 0.3 | calibration_error above this = overconfident |
| `UNDERCONFIDENCE_THRESHOLD` | -0.3 | calibration_error below this = underconfident |
| `CAPABILITY_STATES` | 4 symbols | `:unknown`, `:developing`, `:competent`, `:expert` |
| `KNOWLEDGE_STATES` | 4 symbols | `:ignorant`, `:aware`, `:familiar`, `:expert` |

## Helpers

### `Helpers::Capability`

Single capability tracked with EMA competence and calibration error.

- `initialize(id:, name:, domain: :general, competence: DEFAULT_COMPETENCE)` — clamps competence to floor/ceiling
- `record_attempt(predicted_success:, actual_success:)` — updates competence and calibration_error via EMA
- `competence_label` — maps competence to `:very_low` through `:very_high`
- `calibrated?` — `calibration_error.abs < 0.15`
- `overconfident?` — `calibration_error > 0.3`
- `underconfident?` — `calibration_error < -0.3`
- `state` — `:unknown` (< 0.2), `:developing` (< 0.5), `:competent` (< 0.8), `:expert` (>= 0.8)

### `Helpers::KnowledgeDomain`

Two-dimensional (depth + breadth) knowledge model.

- `initialize(id:, name:, depth: 0.0, breadth: 0.0)` — confidence = average of depth and breadth
- `deepen(amount:)` — increases depth, recomputes confidence and state
- `broaden(amount:)` — increases breadth, recomputes confidence and state
- `access!` — records last_accessed timestamp
- `state` — `:ignorant` (< 0.2), `:aware` (< 0.5), `:familiar` (< 0.8), `:expert` (>= 0.8)

### `Helpers::SelfModel`

Container. Uses auto-incrementing integer IDs prefixed `:cap_N` and `:dom_N`.

- `add_capability(name:, domain: :general, competence: DEFAULT_COMPETENCE)` — returns nil if at capacity
- `add_knowledge_domain(name:, depth: 0.0, breadth: 0.0)` — returns nil if at capacity
- `predict_success(capability_id:)` — logs prediction to `@predictions`, returns predicted_probability
- `record_outcome(capability_id:, predicted:, actual:)` — calls `cap.record_attempt`, logs to history
- `introspect` — returns overall_confidence, strengths, weaknesses, blind_spots, knowledge_gaps, calibration_report
- `strengths` — capabilities with competence > 0.7
- `weaknesses` — capabilities with competence < 0.3
- `blind_spots` — capabilities with `overconfident? == true`
- `knowledge_gaps` — domains with depth < 0.3
- `can_do?(capability_name)` — true if named capability has competence >= 0.5
- `knows_about?(domain_name)` — true if named domain has confidence >= 0.5
- `calibration_report` — mean calibration error, calibrated count, and label (excellent/good/fair/poor/uncalibrated)
- `overall_confidence` — mean competence across all capabilities

## Runners

All runners are in `Runners::SelfModel`. The `Client` includes this module and owns a `SelfModel` instance via `@model`.

| Runner | Parameters | Returns |
|---|---|---|
| `add_self_capability` | `name:, domain: :general, competence:` | `{ success:, capability_id:, competence:, state: }` |
| `add_self_knowledge` | `name:, depth: 0.0, breadth: 0.0` | `{ success:, domain_id:, depth:, breadth:, state: }` |
| `predict_own_success` | `capability_id:` | `{ success:, capability_id:, predicted_probability:, at: }` |
| `record_self_outcome` | `capability_id:, predicted:, actual:` | `{ success:, competence:, calibration_error: }` |
| `self_introspection` | (none) | Full introspection hash from `SelfModel#introspect` |
| `self_strengths` | (none) | `{ success:, strengths:, count: }` |
| `self_weaknesses` | (none) | `{ success:, weaknesses:, count: }` |
| `self_blind_spots` | (none) | `{ success:, blind_spots:, count: }` |
| `self_calibration_report` | (none) | Calibration report hash |
| `self_model_stats` | (none) | `SelfModel#to_h` summary |

## Integration Points

- **lex-tick / lex-cortex**: `self_introspection` result can be wired to a tick phase to expose metacognitive state to the broader cognitive cycle
- **lex-prediction**: predictions logged by `predict_own_success` pair with `record_self_outcome` to track calibration over time
- **lex-consent**: an agent's confidence in its capabilities can inform consent tier requests
- **lex-volition**: epistemic drive in `DriveSynthesizer` uses prediction confidence; self-model calibration gaps complement this

## Development Notes

- `@model` is memoized in the runner via `model` private method; the `Client` constructor pre-injects a model instance
- `CALIBRATION_ALPHA = 0.1` is the same alpha for both competence updates and calibration_error EMA — they move together
- Calibration error is a signed value: positive = overconfident (predicted success more than actual), negative = underconfident
- History arrays use `shift while size > MAX_HISTORY` (ring-buffer pattern consistent across agentic LEXs)
- `calibration_report` label loop uses `break` to return early — will return `Float::INFINITY` label (`:uncalibrated`) if nothing matches
