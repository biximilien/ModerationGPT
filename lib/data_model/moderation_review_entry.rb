require "json"

module DataModel
  ModerationReviewEntry = Struct.new(
    :created_at,
    :server_id,
    :channel_id,
    :message_id,
    :user_id,
    :strategy,
    :action,
    :shadow_mode,
    :flagged,
    :categories,
    :category_scores,
    :rewrite,
    :automod_outcome,
    keyword_init: true,
  ) do
    def to_h
      {
        created_at: created_at,
        server_id: server_id,
        channel_id: channel_id,
        message_id: message_id,
        user_id: user_id,
        strategy: strategy,
        action: action,
        shadow_mode: shadow_mode,
        flagged: flagged,
        categories: categories,
        category_scores: category_scores,
        rewrite: rewrite,
        automod_outcome: automod_outcome,
      }.compact
    end

    def to_json(*)
      JSON.generate(to_h)
    end

    def self.from_json(payload)
      data = JSON.parse(payload, symbolize_names: true)
      new(**data)
    end
  end
end
