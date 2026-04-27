module Harassment
  class IncidentCollection
    def initialize(incidents)
      @incidents = incidents
    end

    def recent(server_id:, channel_id:, limit: 10, user_id: nil, since: nil)
      incidents = matching_channel(server_id:, channel_id:)
      incidents = matching_user(incidents, user_id) if user_id
      incidents = since(incidents, since) if since

      incidents
        .sort_by(&:classified_at)
        .reverse
        .first(limit)
    end

    def for_author(server_id:, user_id:)
      normalized_server_id = server_id.to_s
      normalized_user_id = user_id.to_s

      @incidents
        .select { |incident| incident.server_id == normalized_server_id && incident.author_id == normalized_user_id }
        .sort_by(&:classified_at)
    end

    private

    def matching_channel(server_id:, channel_id:)
      normalized_server_id = server_id.to_s
      normalized_channel_id = channel_id.to_s

      @incidents.select do |incident|
        incident.server_id == normalized_server_id && incident.channel_id == normalized_channel_id
      end
    end

    def matching_user(incidents, user_id)
      normalized_user_id = user_id.to_s
      incidents.select do |incident|
        incident.author_id == normalized_user_id || incident.target_user_ids.include?(normalized_user_id)
      end
    end

    def since(incidents, timestamp)
      incidents.select { |incident| incident.classified_at >= timestamp.utc }
    end
  end
end
