require "redis"
require_relative "../environment"
require_relative "data_model/keys"
require_relative "data_model/karma_event"

module Backend
  KARMA_AUDIT_LIMIT = 50

  def initialize_backend
    @redis ||= Redis.new(url: Environment.redis_url)
    raise "Redis connection failed" unless @redis.ping == "PONG"
  end

  def add_user_to_watch_list(server_id, user_id)
    @redis.sadd(DataModel::Keys.watchlist(server_id), user_id)
  end

  def remove_user_from_watch_list(server_id, user_id)
    @redis.srem(DataModel::Keys.watchlist(server_id), user_id.to_s)
  end

  def get_watch_list_users(server_id)
    @redis.smembers(DataModel::Keys.watchlist(server_id)).map(&:to_i)
  end

  def get_user_karma(server_id, user_id)
    @redis.hget(DataModel::Keys.karma(server_id), user_id).to_i
  end

  def decrement_user_karma(server_id, user_id, amount = 1, source: "automated_infraction", actor_id: nil, reason: nil)
    delta = -amount
    score = @redis.hincrby(DataModel::Keys.karma(server_id), user_id, delta)
    record_karma_audit_event(server_id, user_id, delta:, score:, source:, actor_id:, reason:)
    score
  end

  def increment_user_karma(server_id, user_id, amount = 1, source: "manual_adjustment", actor_id: nil, reason: nil)
    score = @redis.hincrby(DataModel::Keys.karma(server_id), user_id, amount)
    record_karma_audit_event(server_id, user_id, delta: amount, score:, source:, actor_id:, reason:)
    score
  end

  def set_user_karma(server_id, user_id, score, source: "manual_reset", actor_id: nil, reason: nil)
    previous_score = get_user_karma(server_id, user_id)
    @redis.hset(DataModel::Keys.karma(server_id), user_id, score)
    record_karma_audit_event(server_id, user_id, delta: score - previous_score, score:, source:, actor_id:, reason:)
    score
  end

  def record_user_karma_event(server_id, user_id, score:, source:, delta: 0, actor_id: nil, reason: nil)
    record_karma_audit_event(server_id, user_id, delta:, score:, source:, actor_id:, reason:)
  end

  def get_user_karma_history(server_id, user_id, limit = 5)
    history_limit = [[limit.to_i, 1].max, KARMA_AUDIT_LIMIT].min
    @redis.lrange(DataModel::Keys.karma_history(server_id, user_id), 0, history_limit - 1).map do |entry|
      DataModel::KarmaEvent.from_json(entry).to_h.compact
    end
  end

  def add_server(server_id)
    @redis.sadd(DataModel::Keys.servers, server_id)
  end

  def remove_server(server_id)
    @redis.srem(DataModel::Keys.servers, server_id)
  end

  def get_servers
    @redis.smembers(DataModel::Keys.servers).map(&:to_i)
  end

  private

  def record_karma_audit_event(server_id, user_id, delta:, score:, source:, actor_id:, reason:)
    event = DataModel::KarmaEvent.build(delta:, score:, source:, actor_id:, reason:)

    key = DataModel::Keys.karma_history(server_id, user_id)
    @redis.lpush(key, event.to_json)
    @redis.ltrim(key, 0, KARMA_AUDIT_LIMIT - 1)
  end
end
