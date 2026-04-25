require_relative "classification_record_repository"

module Harassment
  module Repositories
    class InMemoryClassificationRecordRepository < ClassificationRecordRepository
      def initialize
        @records = {}
      end

      def save(record)
        key = repository_key(record.message_id, record.classifier_version)
        raise ArgumentError, "classification record already exists for #{key}" if @records.key?(key)

        @records[key] = record
      end

      def find(message_id:, classifier_version:)
        @records[repository_key(message_id, classifier_version)]
      end

      def all_for_message(message_id)
        normalized_message_id = message_id.to_s
        @records.values.select { |record| record.message_id == normalized_message_id }.sort_by(&:classified_at)
      end

      def latest_for_message(message_id)
        all_for_message(message_id).last
      end

      private

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
