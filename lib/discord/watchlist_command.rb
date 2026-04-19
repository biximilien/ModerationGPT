module Discord
  class WatchlistCommand
    USAGE = "Usage: !moderation watchlist [add|remove @user] OR !moderation karma @user".freeze
    TRIGGER_PATTERN = /\A!moderation\b/i.freeze
    COMMAND_PATTERN = /\A!moderation(?:\s+(?<command>watchlist|karma))?(?:\s+(?<subcommand>add|remove))?(?:\s+<@!?(?<user_id>\d+)>)?\s*\z/i.freeze

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
      unless match
        event.respond(USAGE)
        return
      end

      case match[:subcommand]
      when nil then respond_to_top_level_command(event, match)
      when "add" then add_watchlist_user(event, match)
      when "remove" then remove_watchlist_user(event, match)
      else event.respond(USAGE)
      end
    end

    def respond_to_top_level_command(event, match)
      case match[:command]
      when "watchlist"
        event.respond("Watch list: #{watch_list_mentions(event.server.id)}")
      when "karma"
        respond_with_karma(event, match)
      else
        event.respond(USAGE)
      end
    end

    def add_watchlist_user(event, match)
      unless match[:command] == "watchlist" && match[:user_id]
        event.respond(USAGE)
        return
      end

      @store.add_user_to_watch_list(event.server.id, match[:user_id].to_i)
      event.respond("Added <@#{match[:user_id]}> to watch list")
    end

    def remove_watchlist_user(event, match)
      unless match[:command] == "watchlist" && match[:user_id]
        event.respond(USAGE)
        return
      end

      @store.remove_user_from_watch_list(event.server.id, match[:user_id].to_i)
      event.respond("Removed <@#{match[:user_id]}> from watch list")
    end

    def respond_with_karma(event, match)
      unless match[:user_id]
        event.respond(USAGE)
        return
      end

      karma = @store.get_user_karma(event.server.id, match[:user_id].to_i)
      event.respond("Karma for <@#{match[:user_id]}>: #{karma}")
    end

    def watch_list_mentions(server_id)
      @store.get_watch_list_users(server_id).map { |user_id| "<@#{user_id}>" }.join(", ")
    end
  end
end
