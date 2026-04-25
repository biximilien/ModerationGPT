require_relative "classification_job_repository"

module Harassment
  module Repositories
    class InMemoryClassificationJobRepository < ClassificationJobRepository
      def initialize
        @jobs = {}
      end

      def enqueue_unique(job)
        key = repository_key(job.message_id, job.classifier_version)
        @jobs[key] ||= job
      end

      def find(message_id:, classifier_version:)
        @jobs[repository_key(message_id, classifier_version)]
      end

      def save(job)
        @jobs[repository_key(job.message_id, job.classifier_version)] = job
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

      def repository_key(message_id, classifier_version)
        normalized_message_id = message_id.to_s
        normalized_version =
          case classifier_version
          when ClassifierVersion then classifier_version.value
          else ClassifierVersion.build(classifier_version).value
          end

        "#{normalized_message_id}:#{normalized_version}"
      end
    end
  end
end
