require "json"
require "time"

module DataModel
  KarmaEvent = Data.define(:created_at, :delta, :score, :source, :actor_id, :reason) do
    def self.build(delta:, score:, source:, actor_id: nil, reason: nil, created_at: Time.now.utc.iso8601)
      new(created_at:, delta:, score:, source:, actor_id:, reason:)
    end

    def self.from_json(json)
      attributes = JSON.parse(json, symbolize_names: true)
      new(
        created_at: attributes.fetch(:created_at),
        delta: attributes.fetch(:delta),
        score: attributes.fetch(:score),
        source: attributes.fetch(:source),
        actor_id: attributes[:actor_id],
        reason: attributes[:reason],
      )
    end

    def to_json(*)
      JSON.generate(to_h.compact)
    end
  end
end
