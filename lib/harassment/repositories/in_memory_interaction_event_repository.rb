require_relative "interaction_event_repository"

module Harassment
  module Repositories
    class InMemoryInteractionEventRepository < InteractionEventRepository
      def initialize
        @events = {}
      end

      def save(event)
        message_id = event.message_id
        raise ArgumentError, "interaction event already exists for message_id=#{message_id}" if @events.key?(message_id)

        @events[message_id] = event
      end

      def find(message_id)
        @events[message_id.to_s]
      end

      def update_classification_status(message_id, status)
        event = find(message_id)
        return nil unless event

        updated = event.with_classification_status(status)
        @events[event.message_id] = updated
      end

      def list_by_classification_status(status)
        normalized_status = normalize_status(status)
        @events.values.select { |event| event.classification_status == normalized_status }
      end

      private

      def normalize_status(status)
        return status if ClassificationStatus::ALL.include?(status)

        InteractionEvent.build(
          message_id: "validation",
          server_id: "validation",
          channel_id: "validation",
          author_id: "validation",
          raw_content: "validation",
          classification_status: status,
        ).classification_status
      end
    end
  end
end
