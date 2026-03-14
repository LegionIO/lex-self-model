# frozen_string_literal: true

RSpec.describe Legion::Extensions::SelfModel::Client do
  subject(:client) { described_class.new }

  it 'full lifecycle: add capability and knowledge, predict, record, introspect' do
    cap_result = client.add_self_capability(name: 'problem solving', domain: :cognitive, competence: 0.6)
    expect(cap_result[:success]).to be true

    dom_result = client.add_self_knowledge(name: 'algorithms', depth: 0.5, breadth: 0.4)
    expect(dom_result[:success]).to be true

    pred = client.predict_own_success(capability_id: cap_result[:capability_id])
    expect(pred[:success]).to be true
    expect(pred[:predicted_probability]).to be_a(Float)

    outcome = client.record_self_outcome(
      capability_id: cap_result[:capability_id],
      predicted:     true,
      actual:        true
    )
    expect(outcome[:success]).to be true

    introspection = client.self_introspection
    expect(introspection[:success]).to be true
    expect(introspection[:strengths]).to be_an(Array)

    report = client.self_calibration_report
    expect(report[:success]).to be true

    stats = client.self_model_stats
    expect(stats[:capability_count]).to eq(1)
    expect(stats[:knowledge_domain_count]).to eq(1)
  end

  it 'accepts injected model' do
    injected = Legion::Extensions::SelfModel::Helpers::SelfModel.new
    c = described_class.new(model: injected)
    c.add_self_capability(name: 'testing')
    expect(injected.capabilities.size).to eq(1)
  end

  it 'tracks strengths and weaknesses separately' do
    client.add_self_capability(name: 'expert task', competence: 0.9)
    client.add_self_capability(name: 'beginner task', competence: 0.1)

    strengths  = client.self_strengths
    weaknesses = client.self_weaknesses

    expect(strengths[:count]).to eq(1)
    expect(weaknesses[:count]).to eq(1)
    expect(strengths[:strengths].first[:name]).to eq('expert task')
    expect(weaknesses[:weaknesses].first[:name]).to eq('beginner task')
  end
end
