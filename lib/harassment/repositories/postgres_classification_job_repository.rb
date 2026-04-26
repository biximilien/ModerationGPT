require "time"
require_relative "classification_job_repository"
require_relative "postgres_helpers"

module Harassment
  module Repositories
    class PostgresClassificationJobRepository < ClassificationJobRepository
      include PostgresHelpers

      def initialize(connection:)
        @connection = connection
      end

      def enqueue_unique(job)
        row = first_row(
          @connection.exec_params(
            <<~SQL,
              INSERT INTO classification_jobs (
                guild_id,
                message_id,
                classifier_version,
                status,
                attempt_count,
                available_at,
                last_error_class,
                last_error_message,
                enqueued_at,
                updated_at
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
              ON CONFLICT (guild_id, message_id, classifier_version) DO NOTHING
              RETURNING *
            SQL
            serialize_job(job),
          ),
        )
        return deserialize_job(row) if row

        find(server_id: job.server_id, message_id: job.message_id, classifier_version: job.classifier_version)
      end

      def find(server_id:, message_id:, classifier_version:)
        row = first_row(
          @connection.exec_params(
            <<~SQL,
              SELECT *
              FROM classification_jobs
              WHERE guild_id = $1
                AND message_id = $2
                AND classifier_version = $3
              LIMIT 1
            SQL
            [server_id.to_s, message_id.to_s, normalize_classifier_version(classifier_version)],
          ),
        )
        row ? deserialize_job(row) : nil
      end

      def save(job)
        row = first_row(
          @connection.exec_params(
            <<~SQL,
              UPDATE classification_jobs
              SET status = $4,
                  attempt_count = $5,
                  available_at = $6,
                  last_error_class = $7,
                  last_error_message = $8,
                  enqueued_at = $9,
                  updated_at = $10
              WHERE guild_id = $1
                AND message_id = $2
                AND classifier_version = $3
              RETURNING *
            SQL
            serialize_job(job),
          ),
        )
        row ? deserialize_job(row) : nil
      end

      def due_jobs(as_of: Time.now.utc)
        rows(
          @connection.exec_params(
            <<~SQL,
              SELECT *
              FROM classification_jobs
              WHERE available_at <= $1
                AND status IN ('pending', 'failed_retryable')
              ORDER BY available_at ASC
            SQL
            [as_of.utc.iso8601(9)],
          ),
        ).map { |row| deserialize_job(row) }
      end

      private

      def serialize_job(job)
        [
          job.server_id,
          job.message_id,
          job.classifier_version.value,
          job.status,
          job.attempt_count,
          job.available_at.iso8601(9),
          job.last_error_class,
          job.last_error_message,
          job.enqueued_at.iso8601(9),
          job.updated_at.iso8601(9),
        ]
      end

      def deserialize_job(row)
        ClassificationJob.build(
          server_id: row.fetch("guild_id"),
          message_id: row.fetch("message_id"),
          classifier_version: row.fetch("classifier_version"),
          status: row.fetch("status"),
          attempt_count: row.fetch("attempt_count"),
          available_at: row.fetch("available_at"),
          last_error_class: row["last_error_class"],
          last_error_message: row["last_error_message"],
          enqueued_at: row.fetch("enqueued_at"),
          updated_at: row.fetch("updated_at"),
        )
      end

    end
  end
end
