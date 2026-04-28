require "moderation/review_action"

describe Moderation::ReviewAction do
  it "defines persisted review action values" do
    expect(described_class::REMOVED).to eq("removed")
    expect(described_class::REWRITTEN).to eq("rewritten")
    expect(described_class::WOULD_REMOVE).to eq("would_remove")
    expect(described_class::WOULD_REWRITE).to eq("would_rewrite")
  end
end
