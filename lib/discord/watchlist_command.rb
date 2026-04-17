module Discord
  class WatchlistCommand
    USAGE = "Usage: !moderation watchlist [add|remove @user]".freeze
    TRIGGER_PATTERN = /\A!moderation\b/i.freeze
    COMMAND_PATTERN = /\A!moderation(?:\s+(?<command>watchlist))?(?:\s+(?<subcommand>add|remove)\s+<@!?(?<user_id>\d+)>)?\s*\z/i.freeze

    def initialize(store)
      @store = store
    end

    def matches?(event)
      TRIGGER_PATTERN.match?(event.message.content)
    end

    def handle(event)
      match = COMMAND_PATTERN.match(event.message.content)
      return false unless matches?(event)

      $logger.info("Moderation command from #{event.user.name} (#{event.user.id})")
      return true unless administrator?(event)

      respond_to_command(event, match)
      true
    end

    private

    def administrator?(event)
      event.server.members.any? do |member|
        member.id == event.user.id && member.permission?(:administrator)
      end
    end

    def respond_to_command(event, match)
      unless match && match[:command] == "watchlist"
        event.respond(USAGE)
        return
      end

      case match[:subcommand]
      when nil
        event.respond("Watch list: #{watch_list_mentions(event.server.id)}")
      when "add"
        @store.add_user_to_watch_list(event.server.id, match[:user_id].to_i)
        event.respond("Added <@#{match[:user_id]}> to watch list")
      when "remove"
        @store.remove_user_from_watch_list(event.server.id, match[:user_id].to_i)
        event.respond("Removed <@#{match[:user_id]}> from watch list")
      else
        event.respond(USAGE)
      end
    end

    def watch_list_mentions(server_id)
      @store.get_watch_list_users(server_id).map { |user_id| "<@#{user_id}>" }.join(", ")
    end
  end
end
