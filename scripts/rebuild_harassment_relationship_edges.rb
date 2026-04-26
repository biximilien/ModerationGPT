require_relative "../environment"
require_relative "../lib/application"
require_relative "../lib/harassment/relationship_edge_rebuilder"
require_relative "../lib/harassment/repository_factory"
require_relative "../lib/plugins/harassment_plugin"

app = ModerationGPT::Application.new
factory = Harassment::RepositoryFactory.new(
  backend: Environment.harassment_storage_backend,
  redis: app.redis,
  connection: (Environment.harassment_storage_backend == "postgres" ? app.database_connection : nil),
)
plugin = ModerationGPT::Plugins::HarassmentPlugin.new
server_id = ARGV[0]

rebuilder = Harassment::RelationshipEdgeRebuilder.new(
  interaction_events: factory.interaction_events,
  classification_records: factory.classification_records,
  relationship_edges: factory.relationship_edges,
  score_version: plugin.score_version,
  server_id: server_id,
)

summary = rebuilder.run

puts "Harassment relationship-edge rebuild complete"
puts "- score_version=#{plugin.score_version}"
puts "- server_scope=#{server_id || 'all'}"
summary.each do |name, count|
  puts "- #{name}=#{count}"
end
