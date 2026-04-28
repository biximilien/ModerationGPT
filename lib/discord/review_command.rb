module Discord
  class ReviewCommand
    DEFAULT_LIMIT = 5
    MAX_LIMIT = 10
    PREVIEW_LIMIT = 120

    def initialize(store:, usage:)
      @store = store
      @usage = usage
    end

    def handle(event, match)
      case match[:subcommand]
      when nil, "recent" then respond_with_reviews(event, match)
      when "clear" then clear_reviews(event, match)
      when "restore" then restore_review(event, match)
      else event.respond(@usage)
      end
    end

    private

    def respond_with_reviews(event, match)
      entries = @store.get_moderation_reviews(
        event.server.id,
        review_limit(match),
        user_id: match[:user_id],
      )
      event.respond(review_response(entries, user_id: match[:user_id]))
    end

    def clear_reviews(event, match)
      return event.respond(@usage) if match[:user_id] || match[:amount]

      @store.clear_moderation_reviews(event.server.id)
      event.respond("Cleared moderation review queue")
    end

    def restore_review(event, match)
      return event.respond(@usage) unless match[:amount]

      entry = @store.find_moderation_review(event.server.id, match[:amount])
      return event.respond("No moderation review found for message #{match[:amount]}") unless entry

      content = entry[:original_content].to_s.strip
      return event.respond("Original content was not stored for message #{match[:amount]}") if content.empty?

      event.respond("Restored message from <@#{entry[:user_id]}>:\n#{content}")
    end

    def review_limit(match)
      limit = match[:amount]&.to_i || DEFAULT_LIMIT
      [[limit, 1].max, MAX_LIMIT].min
    end

    def review_response(entries, user_id:)
      subject = user_id ? " for <@#{user_id}>" : ""
      return "No moderation reviews#{subject}" if entries.empty?

      lines = entries.map { |entry| review_line(entry) }
      "Moderation reviews#{subject}:\n#{lines.join("\n")}"
    end

    def review_line(entry)
      mode = entry[:shadow_mode] ? "shadow" : "live"
      rewrite = entry[:rewrite] ? " rewrite=#{preview(entry[:rewrite]).inspect}" : ""
      automod = entry[:automod_outcome] ? " automod=#{entry[:automod_outcome]}" : ""
      "- #{entry[:created_at]} #{mode} #{entry[:action]} <@#{entry[:user_id]}> msg=#{entry[:message_id]} via #{entry[:strategy]}#{automod}#{rewrite}"
    end

    def preview(value)
      text = value.to_s.gsub(/\s+/, " ").strip
      return text if text.length <= PREVIEW_LIMIT

      "#{text[0, PREVIEW_LIMIT]}..."
    end
  end
end
