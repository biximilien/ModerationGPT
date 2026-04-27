require_relative "../data_model/keys"

module Backend
  module WatchlistStore
    def add_user_to_watch_list(server_id, user_id)
      @redis.sadd(DataModel::Keys.watchlist(server_id), user_id)
    end

    def remove_user_from_watch_list(server_id, user_id)
      @redis.srem(DataModel::Keys.watchlist(server_id), user_id.to_s)
    end

    def get_watch_list_users(server_id)
      @redis.smembers(DataModel::Keys.watchlist(server_id)).map(&:to_i)
    end
  end
end
