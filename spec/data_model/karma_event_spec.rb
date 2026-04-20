require "data_model/karma_event"

describe DataModel::KarmaEvent do
  it "builds a karma event with a timestamp" do
    event = described_class.build(delta: -1, score: -5, source: "automated_infraction")

    expect(event.delta).to eq(-1)
    expect(event.score).to eq(-5)
    expect(event.source).to eq("automated_infraction")
    expect(event.created_at).to match(/\A\d{4}-\d{2}-\d{2}T/)
  end

  it "serializes optional nil fields out of JSON" do
    event = described_class.build(delta: 0, score: -5, source: "automod_timeout_applied")

    expect(JSON.parse(event.to_json)).not_to include("actor_id", "reason")
  end

  it "round-trips from JSON" do
    event = described_class.build(
      created_at: "2026-04-20T12:00:00Z",
      delta: 2,
      score: -3,
      source: "manual_adjustment",
      actor_id: 42,
      reason: "appeal",
    )

    parsed = described_class.from_json(event.to_json)

    expect(parsed).to eq(event)
  end
end
