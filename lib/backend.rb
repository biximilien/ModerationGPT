require "redis"
require_relative "../environment"
require_relative "backend/karma_store"
require_relative "backend/moderation_review_store"
require_relative "backend/server_store"
require_relative "backend/watchlist_store"

module Backend
  include KarmaStore
  include ModerationReviewStore
  include ServerStore
  include WatchlistStore

  def initialize_backend
    @redis ||= Redis.new(url: Environment.redis_url)
    raise "Redis connection failed" unless @redis.ping == "PONG"
  end

  def redis
    @redis
  end
end
