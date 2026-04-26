require_relative "../environment"
require_relative "../lib/application"
require_relative "../lib/harassment/postgres_verifier"

app = ModerationGPT::Application.new

verifier = Harassment::PostgresVerifier.new(
  redis: app.redis,
  connection: app.database_connection,
)

summary = verifier.run

puts "Harassment Postgres verification"
summary.each do |name, counts|
  puts "- #{name}: redis_total=#{counts[:redis_total]} postgres_total=#{counts[:postgres_total]} matches=#{counts[:matches]}"
  counts[:redis_by_server].each do |server_id, redis_count|
    postgres_count = counts[:postgres_by_server].fetch(server_id, 0)
    puts "  - server #{server_id}: redis=#{redis_count} postgres=#{postgres_count}"
  end
end
