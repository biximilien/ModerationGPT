require_relative "classification_job_repository"
require_relative "repository_keys"

module Harassment
  module Repositories
    class InMemoryClassificationJobRepository < ClassificationJobRepository
      include RepositoryKeys

      def initialize
        @jobs = {}
      end

      def enqueue_unique(job)
        key = classification_key(job.server_id, job.message_id, job.classifier_version)
        @jobs[key] ||= job
      end

      def find(server_id:, message_id:, classifier_version:)
        @jobs[classification_key(server_id, message_id, classifier_version)]
      end

      def save(job)
        @jobs[classification_key(job.server_id, job.message_id, job.classifier_version)] = job
      end

      def due_jobs(as_of: Time.now.utc)
        @jobs.values
             .select { |job| job.available_at <= as_of && retryable_or_pending?(job.status) }
             .sort_by(&:available_at)
      end

      private

      def retryable_or_pending?(status)
        [ClassificationStatus::PENDING, ClassificationStatus::FAILED_RETRYABLE].include?(status)
      end
    end
  end
end
