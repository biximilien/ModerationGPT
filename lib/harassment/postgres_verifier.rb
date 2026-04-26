require "json"
require_relative "../data_model/keys"
require_relative "repositories/postgres_classification_job_repository"
require_relative "repositories/postgres_classification_record_repository"
require_relative "repositories/postgres_interaction_event_repository"

module Harassment
  class PostgresVerifier
    TABLES = {
      interaction_events: {
        redis_key: DataModel::Keys.harassment_interaction_events,
        table_name: "interaction_events",
      },
      classification_records: {
        redis_key: DataModel::Keys.harassment_classification_records,
        table_name: "classification_records",
      },
      classification_jobs: {
        redis_key: DataModel::Keys.harassment_classification_jobs,
        table_name: "classification_jobs",
      },
    }.freeze

    DEFAULT_SPOT_CHECK_LIMIT = 5

    def initialize(
      redis:,
      connection:,
      interaction_event_repository: nil,
      classification_record_repository: nil,
      classification_job_repository: nil
    )
      @redis = redis
      @connection = connection
      @interaction_event_repository =
        interaction_event_repository || Repositories::PostgresInteractionEventRepository.new(connection:)
      @classification_record_repository =
        classification_record_repository || Repositories::PostgresClassificationRecordRepository.new(connection:)
      @classification_job_repository =
        classification_job_repository || Repositories::PostgresClassificationJobRepository.new(connection:)
    end

    def run(spot_check_limit: DEFAULT_SPOT_CHECK_LIMIT)
      summary = TABLES.each_with_object({}) do |(name, config), counts_summary|
        redis_counts = redis_counts_for(config.fetch(:redis_key))
        postgres_counts = postgres_counts_for(config.fetch(:table_name))

        counts_summary[name] = {
          redis_total: redis_counts.fetch(:total),
          postgres_total: postgres_counts.fetch(:total),
          redis_by_server: redis_counts.fetch(:by_server),
          postgres_by_server: postgres_counts.fetch(:by_server),
          matches: redis_counts == postgres_counts,
        }
      end

      summary[:spot_checks] = {
        interaction_events: spot_check_interaction_events(limit: spot_check_limit),
        classification_records: spot_check_classification_records(limit: spot_check_limit),
        classification_jobs: spot_check_classification_jobs(limit: spot_check_limit),
      }
      summary
    end

    private

    def redis_counts_for(key)
      by_server = Hash.new(0)
      @redis.hgetall(key).each_value do |payload|
        data = JSON.parse(payload)
        by_server[data.fetch("server_id").to_s] += 1
      end

      {
        total: by_server.values.sum,
        by_server: by_server.sort.to_h,
      }
    end

    def postgres_counts_for(table_name)
      total_row = first_row(
        @connection.exec_params(
          <<~SQL,
            SELECT COUNT(*) AS count
            FROM #{table_name}
          SQL
          [],
        ),
      )
      server_rows = rows(
        @connection.exec_params(
          <<~SQL,
            SELECT guild_id, COUNT(*) AS count
            FROM #{table_name}
            GROUP BY guild_id
            ORDER BY guild_id ASC
          SQL
          [],
        ),
      )

      {
        total: total_row.fetch("count").to_i,
        by_server: server_rows.to_h { |row| [row.fetch("guild_id").to_s, row.fetch("count").to_i] },
      }
    end

    def first_row(result)
      rows(result).first || {}
    end

    def spot_check_interaction_events(limit:)
      source_events = redis_rows_for(DataModel::Keys.harassment_interaction_events).take(limit)
      build_spot_check_summary(source_events) do |data|
        postgres_event = @interaction_event_repository.find(data.fetch("message_id"))
        next [false, { message_id: data.fetch("message_id").to_s, reason: "missing" }] unless postgres_event

        expected = {
          server_id: data.fetch("server_id").to_s,
          classification_status: data.fetch("classification_status").to_s,
          raw_content: data.fetch("raw_content").to_s,
        }
        actual = {
          server_id: postgres_event.server_id,
          classification_status: postgres_event.classification_status,
          raw_content: postgres_event.raw_content,
        }

        compare_spot_check_record(
          identifier: { message_id: data.fetch("message_id").to_s },
          expected:,
          actual:,
        )
      end
    end

    def spot_check_classification_records(limit:)
      source_records = redis_rows_for(DataModel::Keys.harassment_classification_records).take(limit)
      build_spot_check_summary(source_records) do |data|
        postgres_record = @classification_record_repository.find(
          server_id: data.fetch("server_id"),
          message_id: data.fetch("message_id"),
          classifier_version: data.fetch("classifier_version"),
        )
        identifier = {
          server_id: data.fetch("server_id").to_s,
          message_id: data.fetch("message_id").to_s,
          classifier_version: data.fetch("classifier_version").to_s,
        }
        next [false, identifier.merge(reason: "missing")] unless postgres_record

        expected = {
          model_version: data.fetch("model_version").to_s,
          prompt_version: data.fetch("prompt_version").to_s,
          severity_score: data.fetch("severity_score").to_f,
          confidence: data.fetch("confidence").to_f,
        }
        actual = {
          model_version: postgres_record.model_version,
          prompt_version: postgres_record.prompt_version,
          severity_score: postgres_record.severity_score,
          confidence: postgres_record.confidence,
        }

        compare_spot_check_record(identifier:, expected:, actual:)
      end
    end

    def spot_check_classification_jobs(limit:)
      source_jobs = redis_rows_for(DataModel::Keys.harassment_classification_jobs).take(limit)
      build_spot_check_summary(source_jobs) do |data|
        postgres_job = @classification_job_repository.find(
          server_id: data.fetch("server_id"),
          message_id: data.fetch("message_id"),
          classifier_version: data.fetch("classifier_version"),
        )
        identifier = {
          server_id: data.fetch("server_id").to_s,
          message_id: data.fetch("message_id").to_s,
          classifier_version: data.fetch("classifier_version").to_s,
        }
        next [false, identifier.merge(reason: "missing")] unless postgres_job

        expected = {
          status: data.fetch("status").to_s,
          attempt_count: data.fetch("attempt_count").to_i,
        }
        actual = {
          status: postgres_job.status,
          attempt_count: postgres_job.attempt_count,
        }

        compare_spot_check_record(identifier:, expected:, actual:)
      end
    end

    def build_spot_check_summary(source_rows)
      mismatches = []
      matched = 0

      source_rows.each do |data|
        row_matched, details = yield(data)
        if row_matched
          matched += 1
        else
          mismatches << details
        end
      end

      {
        sampled: source_rows.length,
        matched:,
        mismatches:,
        matches: mismatches.empty?,
      }
    end

    def compare_spot_check_record(identifier:, expected:, actual:)
      return [true, nil] if expected == actual

      mismatch_fields = expected.each_with_object({}) do |(field, expected_value), result|
        actual_value = actual.fetch(field)
        next if actual_value == expected_value

        result[field] = { expected: expected_value, actual: actual_value }
      end

      [false, identifier.merge(fields: mismatch_fields)]
    end

    def redis_rows_for(key)
      @redis.hgetall(key).values.map { |payload| JSON.parse(payload) }
    end

    def rows(result)
      result.respond_to?(:to_a) ? result.to_a : Array(result)
    end
  end
end
