require "json"
require "time"
require_relative "classification_record_repository"

module Harassment
  module Repositories
    class PostgresClassificationRecordRepository < ClassificationRecordRepository
      def initialize(connection:)
        @connection = connection
      end

      def save(record)
        row = first_row(
          @connection.exec_params(
            <<~SQL,
              INSERT INTO classification_records (
                guild_id,
                message_id,
                classifier_version,
                model_version,
                prompt_version,
                classification,
                severity_score,
                confidence,
                classified_at
              )
              VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7, $8, $9)
              ON CONFLICT (guild_id, message_id, classifier_version) DO NOTHING
              RETURNING *
            SQL
            serialize_record(record),
          ),
        )
        raise ArgumentError, "classification record already exists for #{record.server_id}:#{record.message_id}:#{record.classifier_version.value}" unless row

        deserialize_record(row)
      end

      def find(server_id:, message_id:, classifier_version:)
        row = first_row(
          @connection.exec_params(
            <<~SQL,
              SELECT *
              FROM classification_records
              WHERE guild_id = $1
                AND message_id = $2
                AND classifier_version = $3
              LIMIT 1
            SQL
            [server_id.to_s, message_id.to_s, normalize_classifier_version(classifier_version)],
          ),
        )
        row ? deserialize_record(row) : nil
      end

      def all_for_message(server_id:, message_id:)
        rows(
          @connection.exec_params(
            <<~SQL,
              SELECT *
              FROM classification_records
              WHERE guild_id = $1
                AND message_id = $2
              ORDER BY classified_at ASC
            SQL
            [server_id.to_s, message_id.to_s],
          ),
        ).map { |row| deserialize_record(row) }
      end

      def latest_for_message(server_id:, message_id:)
        row = first_row(
          @connection.exec_params(
            <<~SQL,
              SELECT *
              FROM classification_records
              WHERE guild_id = $1
                AND message_id = $2
              ORDER BY classified_at DESC
              LIMIT 1
            SQL
            [server_id.to_s, message_id.to_s],
          ),
        )
        row ? deserialize_record(row) : nil
      end

      private

      def serialize_record(record)
        [
          record.server_id,
          record.message_id,
          record.classifier_version.value,
          record.model_version,
          record.prompt_version,
          JSON.generate(record.classification),
          record.severity_score,
          record.confidence,
          record.classified_at.iso8601(9),
        ]
      end

      def deserialize_record(row)
        ClassificationRecord.build(
          server_id: row.fetch("guild_id"),
          message_id: row.fetch("message_id"),
          classifier_version: row.fetch("classifier_version"),
          model_version: row.fetch("model_version"),
          prompt_version: row.fetch("prompt_version"),
          classification: parse_classification(row.fetch("classification")),
          severity_score: row.fetch("severity_score"),
          confidence: row.fetch("confidence"),
          classified_at: row.fetch("classified_at"),
        )
      end

      def parse_classification(value)
        case value
        when Hash then value.transform_keys(&:to_sym)
        else deep_symbolize(JSON.parse(value.to_s))
        end
      end

      def deep_symbolize(value)
        case value
        when Hash
          value.each_with_object({}) { |(key, nested), result| result[key.to_sym] = deep_symbolize(nested) }
        when Array
          value.map { |item| deep_symbolize(item) }
        else
          value
        end
      end

      def first_row(result)
        rows(result).first
      end

      def rows(result)
        result.respond_to?(:to_a) ? result.to_a : Array(result)
      end

      def normalize_classifier_version(classifier_version)
        case classifier_version
        when ClassifierVersion then classifier_version.value
        else ClassifierVersion.build(classifier_version).value
        end
      end
    end
  end
end
