module Discord
  class ModerationCommandParser
    TRIGGER_PATTERN = /\A!moderation\b/i.freeze
    COMMAND_PATTERN = /\A!moderation(?:\s+(?<command>help|watchlist|karma))?(?:\s+(?<subcommand>add|remove|reset|history|set))?(?:\s+<@!?(?<user_id>\d+)>)?(?:\s+(?<amount>-?\d+))?\s*\z/i.freeze

    def trigger?(content)
      TRIGGER_PATTERN.match?(content)
    end

    def parse(content)
      COMMAND_PATTERN.match(content)
    end

    def plugin_command_root?(match)
      match[:command].nil? && match[:subcommand].nil? && match[:user_id].nil? && match[:amount].nil?
    end
  end
end
