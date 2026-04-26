require_relative "../environment"
require_relative "../lib/application"
require_relative "../lib/harassment/postgres_bootstrap"
require_relative "../lib/harassment/repositories/postgres_interaction_event_repository"
require_relative "../lib/harassment/repositories/postgres_classification_record_repository"
require_relative "../lib/harassment/repositories/postgres_classification_job_repository"

app = ModerationGPT::Application.new

bootstrap = Harassment::PostgresBootstrap.new(
  redis: app.redis,
  interaction_events: Harassment::Repositories::PostgresInteractionEventRepository.new(connection: app.database_connection),
  classification_records: Harassment::Repositories::PostgresClassificationRecordRepository.new(connection: app.database_connection),
  classification_jobs: Harassment::Repositories::PostgresClassificationJobRepository.new(connection: app.database_connection),
)

summary = bootstrap.run

puts "Harassment Postgres bootstrap complete"
summary.each do |name, counts|
  puts "- #{name}: imported=#{counts[:imported]} skipped=#{counts[:skipped]}"
end
