require "redis"
require_relative "../environment"

module Backend
  def initialize_backend
    @redis ||= Redis.new(url: Environment.redis_url)
    raise "Redis connection failed" unless @redis.ping == "PONG"
  end

  def add_user_to_watch_list(server_id, user_id)
    @redis.sadd("server_#{server_id}_users", user_id)
  end

  def remove_user_from_watch_list(server_id, user_id)
    @redis.srem("server_#{server_id}_users", user_id.to_s)
  end

  def get_watch_list_users(server_id)
    @redis.smembers("server_#{server_id}_users").map(&:to_i)
  end

  def add_server(server_id)
    @redis.sadd("servers", server_id)
  end

  def remove_server(server_id)
    @redis.srem("servers", server_id)
  end

  def get_servers
    @redis.smembers("servers").map(&:to_i)
  end
end
