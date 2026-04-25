require "plugins/harassment_plugin"

describe ModerationGPT::Plugins::HarassmentPlugin do
  subject(:plugin) { described_class.new }

  let(:mentioned_user) { instance_double("User", id: 654) }
  let(:message) do
    instance_double(
      "Message",
      id: 123,
      content: "hello there",
      timestamp: Time.utc(2026, 4, 25, 16, 0, 0),
      mentions: [mentioned_user],
    )
  end
  let(:server) { instance_double("Server", id: 456) }
  let(:channel) { instance_double("Channel", id: 789) }
  let(:user) { instance_double("User", id: 321) }
  let(:event) do
    instance_double("Event", message: message, server: server, channel: channel, user: user)
  end

  let(:record) do
    Harassment::ClassificationRecord.build(
      message_id: 123,
      classifier_version: "harassment-v1",
      classification: { intent: "aggressive", target_type: "individual" },
      severity_score: 0.8,
      confidence: 0.5,
      classified_at: Time.utc(2026, 4, 25, 16, 0, 0),
    )
  end

  it "captures passive interaction events and enqueues classification" do
    interaction_event = plugin.message(event: event)

    expect(interaction_event.message_id).to eq("123")
    expect(interaction_event.target_user_ids).to eq(["654"])
    expect(plugin.classification_jobs.due_jobs.length).to eq(1)
  end

  it "records classified events in its read model" do
    interaction_event = plugin.message(event: event)
    incident = plugin.record_classification(event: interaction_event, record:)

    expect(incident.intent).to eq("aggressive")
    expect(plugin.recent_incidents("789").incidents).to eq([incident])
  end

  it "exposes user risk and pair relationships" do
    interaction_event = plugin.message(event: event)
    plugin.record_classification(event: interaction_event, record:)

    expect(plugin.get_user_risk("321").risk_score).to eq(0.4)
    expect(plugin.get_pair_relationship("321", "654").relationship_edge.interaction_count).to eq(1)
  end

  it "boots an OpenAI-backed classifier worker from the application client" do
    response = { "output_text" => <<~JSON.strip }
      {"intent":"aggressive","target_type":"individual","toxicity_dimensions":{"insult":true,"threat":false,"profanity":false,"exclusion":true,"harassment":true},"severity_score":0.8,"confidence":0.5}
    JSON
    app = instance_double("Application")
    allow(app).to receive(:query).and_return(response)
    allow(app).to receive(:response_text).with(response).and_return(response["output_text"])

    plugin.boot(app: app)
    interaction_event = plugin.message(event: event)

    expect(plugin.classification_jobs.find(message_id: "123", classifier_version: "harassment-v1").status).to eq(Harassment::ClassificationStatus::CLASSIFIED)
    expect(plugin.recent_incidents("789").incidents.map(&:message_id)).to eq(["123"])
    expect(interaction_event.message_id).to eq("123")
  end

  it "processes due classifications explicitly when a classifier is configured" do
    classifier = instance_double("Classifier")
    plugin = described_class.new(classifier: classifier)
    allow(classifier).to receive(:classify).and_return(record)

    plugin.message(event: event)
    results = plugin.process_due_classifications(as_of: Time.utc(2026, 4, 25, 16, 0, 0))

    expect(results).to eq([])
    expect(plugin.recent_incidents("789").incidents.map(&:message_id)).to eq(["123"])
  end
end
