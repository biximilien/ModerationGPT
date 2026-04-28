require_relative "../data_model/keys"

module Backend
  module ServerStore
    def add_server(server_id)
      @redis.sadd(DataModel::Keys.servers, server_id)
    end

    def remove_server(server_id)
      @redis.srem(DataModel::Keys.servers, server_id)
      purge_server_data(server_id)
    end

    def servers
      @redis.smembers(DataModel::Keys.servers).map(&:to_i)
    end

    private

    def purge_server_data(server_id)
      delete_key(DataModel::Keys.watchlist(server_id))
      delete_key(DataModel::Keys.karma(server_id))
      delete_key(DataModel::Keys.moderation_review(server_id))

      @redis.scan_each(match: DataModel::Keys.karma_history_pattern(server_id)) do |key|
        delete_key(key)
      end
    end

    def delete_key(key)
      @redis.del(key)
    end
  end
end
