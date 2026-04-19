require "application"

class FakeApplicationRedis
  def ping
    "PONG"
  end
end

describe ModerationGPT::Application do
  before do
    allow(Redis).to receive(:new).and_return(FakeApplicationRedis.new)
  end

  it "initializes the backend" do
    described_class.new

    expect(Redis).to have_received(:new).with(url: Environment.redis_url)
  end

  it "exposes backend methods" do
    expect(described_class.new).to respond_to(:get_watch_list_users)
  end

  it "exposes OpenAI methods" do
    expect(described_class.new).to respond_to(:moderate_text)
  end
end
