require_relative "../classification/status"
require_relative "../risk/read_model"

module Harassment
  class RelationshipEdgeRebuilder
    def initialize(interaction_events:, classification_records:, relationship_edges:, score_version:, server_id: nil)
      @interaction_events = interaction_events
      @classification_records = classification_records
      @relationship_edges = relationship_edges
      @score_version = score_version.to_s
      @server_id = server_id&.to_s
    end

    def run
      @relationship_edges.delete_all(score_version: @score_version, server_id: @server_id)
      read_model = ReadModel.new(score_version: @score_version, edge_repository: @relationship_edges)

      summary = {
        rebuilt: 0,
        skipped_missing_record: 0,
        skipped_server_scope: 0
      }

      classified_events.each do |event|
        if @server_id && event.server_id != @server_id
          summary[:skipped_server_scope] += 1
          next
        end

        record = @classification_records.latest_for_message(server_id: event.server_id, message_id: event.message_id)
        unless record
          summary[:skipped_missing_record] += 1
          next
        end

        read_model.ingest(event: event, record: record)
        summary[:rebuilt] += 1
      end

      summary
    end

    private

    def classified_events
      @interaction_events
        .list_by_classification_status(ClassificationStatus::CLASSIFIED)
        .sort_by(&:timestamp)
    end
  end
end
