require "harassment/postgres_verifier"
require "harassment/repositories/postgres_classification_job_repository"
require "harassment/repositories/postgres_classification_record_repository"
require "harassment/repositories/postgres_interaction_event_repository"
require "harassment/repositories/redis_classification_job_repository"
require "harassment/repositories/redis_classification_record_repository"
require "harassment/repositories/redis_interaction_event_repository"
require_relative "../support/fake_postgres_connection"
require_relative "../support/fake_redis"

describe Harassment::PostgresVerifier do
  let(:redis) { FakeRedis.new }
  let(:connection) { FakePostgresConnection.new }
  let(:source_interaction_events) { Harassment::Repositories::RedisInteractionEventRepository.new(redis: redis) }
  let(:source_classification_records) { Harassment::Repositories::RedisClassificationRecordRepository.new(redis: redis) }
  let(:source_classification_jobs) { Harassment::Repositories::RedisClassificationJobRepository.new(redis: redis) }
  let(:target_interaction_events) { Harassment::Repositories::PostgresInteractionEventRepository.new(connection: connection) }
  let(:target_classification_records) { Harassment::Repositories::PostgresClassificationRecordRepository.new(connection: connection) }
  let(:target_classification_jobs) { Harassment::Repositories::PostgresClassificationJobRepository.new(connection: connection) }

  subject(:verifier) { described_class.new(redis: redis, connection: connection) }

  before do
    event = Harassment::InteractionEvent.build(
      message_id: 123,
      server_id: 456,
      channel_id: 789,
      author_id: 321,
      raw_content: "hello there",
    )
    record = Harassment::ClassificationRecord.build(
      server_id: 456,
      message_id: 123,
      classifier_version: "harassment-v1",
      model_version: "gpt-4o-2024-08-06",
      prompt_version: "harassment-prompt-v1",
      classification: { intent: "aggressive", target_type: "individual", toxicity_dimensions: {} },
      severity_score: 0.4,
      confidence: 0.8,
    )
    job = Harassment::ClassificationJob.build(
      server_id: 456,
      message_id: 123,
      classifier_version: "harassment-v1",
    )

    source_interaction_events.save(event)
    source_classification_records.save(record)
    source_classification_jobs.enqueue_unique(job)

    target_interaction_events.save(event)
    target_classification_records.save(record)
    target_classification_jobs.enqueue_unique(job)
  end

  it "reports matching totals and per-server counts" do
    summary = verifier.run

    expect(summary[:interaction_events]).to eq(
      redis_total: 1,
      postgres_total: 1,
      redis_by_server: { "456" => 1 },
      postgres_by_server: { "456" => 1 },
      matches: true,
    )
    expect(summary[:classification_records][:matches]).to eq(true)
    expect(summary[:classification_jobs][:matches]).to eq(true)
  end

  it "reports mismatches when counts diverge" do
    target_classification_jobs.enqueue_unique(
      Harassment::ClassificationJob.build(
        server_id: 456,
        message_id: 999,
        classifier_version: "harassment-v1",
      ),
    )

    summary = verifier.run

    expect(summary[:classification_jobs][:redis_total]).to eq(1)
    expect(summary[:classification_jobs][:postgres_total]).to eq(2)
    expect(summary[:classification_jobs][:matches]).to eq(false)
  end
end
