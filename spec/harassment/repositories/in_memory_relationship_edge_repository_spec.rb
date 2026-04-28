require "harassment/repositories/in_memory_relationship_edge_repository"

describe Harassment::Repositories::InMemoryRelationshipEdgeRepository do
  subject(:repository) { described_class.new }

  let(:edge) do
    Harassment::RelationshipEdge.build(
      server_id: 456,
      source_user_id: 321,
      target_user_id: 654,
      score_version: "harassment-score-v1",
      hostility_score: 0.4,
      interaction_count: 1,
      last_interaction_at: Time.utc(2026, 4, 25, 16, 0, 0)
    )
  end

  it "stores and retrieves edges" do
    repository.save(edge)

    expect(
      repository.find(
        server_id: "456",
        source_user_id: "321",
        target_user_id: "654",
        score_version: "harassment-score-v1"
      )
    ).to eq(edge)
  end

  it "deletes edges by score version" do
    repository.save(edge)

    repository.delete_all(score_version: "harassment-score-v1")

    expect(
      repository.find(
        server_id: "456",
        source_user_id: "321",
        target_user_id: "654",
        score_version: "harassment-score-v1"
      )
    ).to be_nil
  end
end
