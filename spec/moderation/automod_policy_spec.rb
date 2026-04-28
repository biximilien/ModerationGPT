require "moderation/automod_policy"

describe Moderation::AutomodPolicy do
  let(:user) { instance_double("User", id: 456) }
  let(:server) { instance_double("Server") }
  let(:event) { instance_double("Event", user: user, server: server) }

  it "logs threshold crossings for log_only policy" do
    policy = described_class.new(action: "log_only")
    allow(Logging.logger).to receive(:warn)

    result = policy.apply(event, -5)

    expect(Logging.logger).to have_received(:warn).with(
      event: "automod_threshold_reached",
      user_hash: Telemetry::Anonymizer.hash(456),
      karma_score: -5,
      action: "log_only"
    )
    expect(result).to eq(Moderation::AutomodOutcome::LOG_ONLY)
  end

  it "times out users for timeout policy" do
    member = instance_double("Member", timeout_for: true)
    allow(event).to receive(:member).and_return(member)

    result = described_class.new(action: "timeout", timeout_seconds: 120).apply(event, -5)

    expect(member).to have_received(:timeout_for).with(120, "Automated moderation: karma -5")
    expect(result).to eq(Moderation::AutomodOutcome::TIMEOUT_APPLIED)
  end

  it "does not time out members with elevated permissions" do
    member = instance_double("Member", timeout_for: true)
    allow(member).to receive(:permission?) { |permission| permission == :moderate_members }
    allow(event).to receive(:member).and_return(member)
    allow(Logging.logger).to receive(:warn)

    result = described_class.new(action: "timeout", timeout_seconds: 120).apply(event, -5)

    expect(result).to eq(Moderation::AutomodOutcome::SKIPPED_ELEVATED_MEMBER)
    expect(member).not_to have_received(:timeout_for)
    expect(Logging.logger).to have_received(:warn).with(
      event: "automod_skipped_elevated_member",
      user_hash: Telemetry::Anonymizer.hash(456),
      karma_score: -5,
      action: "timeout"
    )
  end

  it "uses Discord API fallback for timeout when no member timeout helper exists" do
    bot = instance_double("Bot", token: "discord-token")
    server = instance_double("Server", id: 123)
    server.instance_variable_set(:@bot, bot)
    event = instance_double("Event", user: user, server: server)
    allow(Discordrb::API).to receive(:request)

    result = described_class.new(action: "timeout", timeout_seconds: 120).apply(event, -5)

    expect(Discordrb::API).to have_received(:request).with(
      :guilds_sid_members_uid,
      123,
      :patch,
      "#{Discordrb::API.api_base}/guilds/123/members/456",
      kind_of(String),
      Authorization: "discord-token",
      content_type: :json,
      "X-Audit-Log-Reason": "Automated moderation: karma -5"
    )
    expect(result).to eq(Moderation::AutomodOutcome::TIMEOUT_APPLIED)
  end

  it "reports timeout unavailable when no timeout path exists" do
    allow(Logging.logger).to receive(:warn)

    result = described_class.new(action: "timeout", timeout_seconds: 120).apply(event, -5)

    expect(result).to eq(Moderation::AutomodOutcome::TIMEOUT_UNAVAILABLE)
    expect(Logging.logger).to have_received(:warn).with(
      event: "automod_action_unavailable",
      user_hash: Telemetry::Anonymizer.hash(456),
      karma_score: -5,
      action: "timeout"
    )
  end

  it "falls back to timeout when an invalid policy is configured" do
    member = instance_double("Member", timeout_for: true)
    allow(event).to receive(:member).and_return(member)

    result = described_class.new(action: "nonsense", timeout_seconds: 120).apply(event, -5)

    expect(member).to have_received(:timeout_for).with(120, "Automated moderation: karma -5")
    expect(result).to eq(Moderation::AutomodOutcome::TIMEOUT_APPLIED)
  end

  it "kicks users for kick policy" do
    allow(server).to receive(:kick)

    result = described_class.new(action: "kick").apply(event, -5)

    expect(server).to have_received(:kick).with(user, "Automated moderation: karma -5")
    expect(result).to eq(Moderation::AutomodOutcome::KICK_APPLIED)
  end

  it "reports kick unavailable when no kick path exists" do
    allow(Logging.logger).to receive(:warn)

    result = described_class.new(action: "kick").apply(event, -5)

    expect(result).to eq(Moderation::AutomodOutcome::KICK_UNAVAILABLE)
    expect(Logging.logger).to have_received(:warn).with(
      event: "automod_action_unavailable",
      user_hash: Telemetry::Anonymizer.hash(456),
      karma_score: -5,
      action: "kick"
    )
  end

  it "bans users for ban policy" do
    allow(server).to receive(:ban)

    result = described_class.new(action: "ban").apply(event, -5)

    expect(server).to have_received(:ban).with(user, 0, reason: "Automated moderation: karma -5")
    expect(result).to eq(Moderation::AutomodOutcome::BAN_APPLIED)
  end

  it "reports ban unavailable when no ban path exists" do
    allow(Logging.logger).to receive(:warn)

    result = described_class.new(action: "ban").apply(event, -5)

    expect(result).to eq(Moderation::AutomodOutcome::BAN_UNAVAILABLE)
    expect(Logging.logger).to have_received(:warn).with(
      event: "automod_action_unavailable",
      user_hash: Telemetry::Anonymizer.hash(456),
      karma_score: -5,
      action: "ban"
    )
  end
end
