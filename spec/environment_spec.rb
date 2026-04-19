describe Environment do
  around do |example|
    original = ENV.to_h
    example.run
  ensure
    ENV.replace(original)
  end

  describe ".validate!" do
    it "passes when required variables are present" do
      ENV["OPENAI_API_KEY"] = "openai"
      ENV["DISCORD_BOT_TOKEN"] = "discord"
      ENV["REDIS_URL"] = "redis://localhost:6379/0"

      expect { described_class.validate! }.not_to raise_error
    end

    it "raises with missing required variables" do
      ENV.delete("OPENAI_API_KEY")
      ENV["DISCORD_BOT_TOKEN"] = "discord"
      ENV["REDIS_URL"] = "redis://localhost:6379/0"

      expect { described_class.validate! }.to raise_error(
        RuntimeError,
        "Missing required environment variables: OPENAI_API_KEY",
      )
    end
  end

  describe ".openai_moderation_model" do
    it "returns the default model" do
      ENV.delete("OPENAI_MODERATION_MODEL")

      expect(described_class.openai_moderation_model).to eq("omni-moderation-latest")
    end
  end

  describe ".openai_rewrite_model" do
    it "returns the default model" do
      ENV.delete("OPENAI_REWRITE_MODEL")

      expect(described_class.openai_rewrite_model).to eq("gpt-4.1-mini")
    end
  end

  describe ".karma_automod_threshold" do
    it "returns the default threshold" do
      ENV.delete("KARMA_AUTOMOD_THRESHOLD")

      expect(described_class.karma_automod_threshold).to eq(-5)
    end

    it "returns a configured threshold" do
      ENV["KARMA_AUTOMOD_THRESHOLD"] = "-10"

      expect(described_class.karma_automod_threshold).to eq(-10)
    end
  end
end
