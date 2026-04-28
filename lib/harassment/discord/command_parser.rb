module Harassment
  module Discord
    class CommandParser
      WINDOW_ALIASES = {
        "1h" => 60 * 60,
        "24h" => 24 * 60 * 60,
        "7d" => 7 * 24 * 60 * 60
      }.freeze
      INCIDENTS_PREFIX = "!moderation harassment incidents".freeze
      RISK_PATTERN = /\A!moderation harassment risk <@!?(?<user_id>\d+)>\s*\z/i
      PAIR_PATTERN = /\A!moderation harassment pair <@!?(?<source_user_id>\d+)>\s+<@!?(?<target_user_id>\d+)>\s*\z/i

      def command_match(content)
        risk_match = RISK_PATTERN.match(content)
        return { type: :risk, data: risk_match } if risk_match

        pair_match = PAIR_PATTERN.match(content)
        return { type: :pair, data: pair_match } if pair_match

        incidents_match = parse_incidents_command(content)
        return { type: :incidents, data: incidents_match } if incidents_match

        nil
      end

      private

      def parse_incidents_command(content)
        return nil unless content.downcase.start_with?(INCIDENTS_PREFIX)

        remainder = content[INCIDENTS_PREFIX.length..]&.strip
        return {} if remainder.nil? || remainder.empty?

        parse_incidents_tokens(remainder.split(/\s+/))
      end

      def parse_incidents_tokens(tokens)
        tokens.each_with_object({ user_id: nil, window: nil, limit: nil }) do |token, parsed|
          return nil unless apply_incidents_token(token, parsed)
        end
      end

      def apply_incidents_token(token, parsed)
        mention_match = /\A<@!?(?<user_id>\d+)>\z/.match(token)
        return assign_incidents_value(parsed, :user_id, mention_match[:user_id]) if mention_match

        normalized_token = token.downcase
        return assign_incidents_value(parsed, :window, normalized_token) if WINDOW_ALIASES.key?(normalized_token)
        return assign_incidents_value(parsed, :limit, token) if /\A\d+\z/.match?(token)

        false
      end

      def assign_incidents_value(parsed, key, value)
        return false if parsed[key]

        parsed[key] = value
      end
    end
  end
end
