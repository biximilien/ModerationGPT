require "data_model/keys"

describe DataModel::Keys do
  it "defines the servers key" do
    expect(described_class.servers).to eq("servers")
  end

  it "defines the watchlist key" do
    expect(described_class.watchlist(123)).to eq("server_123_users")
  end

  it "defines the karma score key" do
    expect(described_class.karma(123)).to eq("server_123_karma")
  end

  it "defines the karma history key" do
    expect(described_class.karma_history(123, 456)).to eq("server_123_user_456_karma_history")
  end
end
