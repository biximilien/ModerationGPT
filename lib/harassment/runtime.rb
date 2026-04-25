require_relative "classification_pipeline"
require_relative "classification_worker"
require_relative "classifier_version"
require_relative "context_assembler"
require_relative "message_ingestor"
require_relative "open_ai_classifier"
require_relative "repositories/in_memory_classification_job_repository"
require_relative "repositories/in_memory_classification_record_repository"
require_relative "repositories/in_memory_interaction_event_repository"
require_relative "repositories/redis_classification_job_repository"
require_relative "repositories/redis_classification_record_repository"
require_relative "repositories/redis_interaction_event_repository"
require_relative "../../environment"

module Harassment
  class Runtime
    DEFAULT_CLASSIFIER_VERSION = "harassment-v1".freeze

    attr_reader :classification_jobs, :classification_pipeline, :classification_records, :interaction_events

    def initialize(
      client:,
      redis: nil,
      interaction_events: nil,
      classification_records: nil,
      classification_jobs: nil,
      classifier_version: DEFAULT_CLASSIFIER_VERSION,
      classifier: nil,
      on_classification: nil
    )
      @interaction_events = interaction_events || self.class.send(:default_interaction_events, redis)
      @classification_records = classification_records || self.class.send(:default_classification_records, redis)
      @classification_jobs = classification_jobs || self.class.send(:default_classification_jobs, redis)
      @classifier_version = ClassifierVersion.build(classifier_version)
      @classifier = classifier || OpenAIClassifier.new(
        client: client,
        model: Environment.harassment_classifier_model,
      )
      @classification_pipeline = ClassificationPipeline.new(
        interaction_events: @interaction_events,
        classification_records: @classification_records,
        classification_jobs: @classification_jobs,
      )
      @message_ingestor = MessageIngestor.new(
        interaction_events: @interaction_events,
        classification_pipeline: @classification_pipeline,
        classifier_version: @classifier_version,
      )
      @context_assembler = ContextAssembler.new(interaction_events: @interaction_events)
      @classification_worker = ClassificationWorker.new(
        interaction_events: @interaction_events,
        classification_jobs: @classification_jobs,
        classification_pipeline: @classification_pipeline,
        classifier: @classifier,
        context_assembler: @context_assembler,
        on_success: on_classification,
      )
    end

    def ingest_message(event)
      @message_ingestor.ingest(event)
    end

    def process_due_classifications(as_of: Time.now.utc, limit: nil)
      @classification_worker.process_due_jobs(as_of:, limit:)
    end

    class << self
      private

      def default_interaction_events(redis)
        redis ? Repositories::RedisInteractionEventRepository.new(redis:) : Repositories::InMemoryInteractionEventRepository.new
      end

      def default_classification_records(redis)
        redis ? Repositories::RedisClassificationRecordRepository.new(redis:) : Repositories::InMemoryClassificationRecordRepository.new
      end

      def default_classification_jobs(redis)
        redis ? Repositories::RedisClassificationJobRepository.new(redis:) : Repositories::InMemoryClassificationJobRepository.new
      end
    end
  end
end
