require_relative "retention_policy"

module Harassment
  class RetentionManager
    def initialize(interaction_events:, policy: RetentionPolicy.new)
      @interaction_events = interaction_events
      @policy = policy
    end

    def redact_expired_content(as_of: Time.now.utc)
      @interaction_events.list_with_expired_content(as_of:).filter_map do |event|
        next unless @policy.redactable?(event, as_of:)

        @interaction_events.redact_content(event.message_id, server_id: event.server_id, redacted_at: as_of)
      end
    end
  end
end
