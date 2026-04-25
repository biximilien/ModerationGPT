require "harassment/relationship_edge"

describe Harassment::RelationshipEdge do
  it "builds a normalized relationship edge" do
    last_interaction_at = Time.utc(2026, 4, 25, 13, 0, 0)

    edge = described_class.build(
      source_user_id: 123,
      target_user_id: 456,
      hostility_score: 0.75,
      positive_score: 0.25,
      interaction_count: 4,
      last_interaction_at: last_interaction_at,
    )

    expect(edge.source_user_id).to eq("123")
    expect(edge.target_user_id).to eq("456")
    expect(edge.hostility_score).to eq(0.75)
    expect(edge.positive_score).to eq(0.25)
    expect(edge.interaction_count).to eq(4)
    expect(edge.last_interaction_at).to eq(last_interaction_at)
  end

  it "rejects negative scores or counts" do
    expect do
      described_class.build(
        source_user_id: 123,
        target_user_id: 456,
        hostility_score: -0.1,
      )
    end.to raise_error(ArgumentError, "hostility_score must be non-negative")
  end
end
