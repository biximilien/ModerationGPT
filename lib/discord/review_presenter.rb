module Discord
  class ReviewPresenter
    PREVIEW_LIMIT = 120

    def list(entries, user_id: nil)
      subject = user_id ? " for <@#{user_id}>" : ""
      return "No moderation reviews#{subject}" if entries.empty?

      lines = entries.map { |entry| line(entry) }
      "Moderation reviews#{subject}:\n#{lines.join("\n")}"
    end

    def restored(entry)
      "Restored message from <@#{entry[:user_id]}>:\n#{entry[:original_content].to_s.strip}"
    end

    private

    def line(entry)
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
