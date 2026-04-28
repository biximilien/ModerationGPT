require_relative "../telemetry/anonymizer"
require_relative "../logging"

module Discord
  class ReadyHandler
    TEXT_CHANNEL = 0

    def initialize(bot, store)
      @bot = bot
      @store = store
    end

    def handle(_event)
      Logging.info("discord_ready")
      @bot.online

      Logging.info("discord_servers_discovered", server_count: @bot.servers.size)

      @bot.servers.each do |server_id, server|
        Logging.info("discord_server_connected", server_hash: Telemetry::Anonymizer.hash(server_id),
                                                 channel_count: server.channels.size)
        @store.add_server(server_id)
        log_text_channels(server)
      end
    end

    private

    def log_text_channels(server)
      server.channels.each do |channel|
        next unless channel.type == TEXT_CHANNEL

        Logging.info("discord_text_channel_discovered", channel_hash: Telemetry::Anonymizer.hash(channel.id))
      end
    end
  end
end
