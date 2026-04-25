require "harassment/classification_status"

describe Harassment::ClassificationStatus do
  it "defines the supported lifecycle states" do
    expect(described_class::ALL).to eq(%w[pending classified failed_retryable failed_terminal])
  end
end
