require_relative "../strategy"

class WatchListStrategy < ModerationStrategy
  def condition(event)
    return false unless watched_user?(event)

    flagged?(event, log_label: "Watch list moderation")
  end

  def execute(event)
    edited = moderation_rewrite(event)
    reason = "Moderation (rewriting due to negative sentiment)"
    event.message.delete(reason)
    record_infraction(event)
    event.respond(response_message(event.user.id, edited))
  end

  private

  def watched_user?(event)
    @bot.get_watch_list_users(event.server.id.to_i).include?(event.user.id.to_i)
  end

  def moderation_rewrite(event)
    instructions = @plugin_registry&.rewrite_instructions(event: event, app: @bot, strategy: self.class.name)
    return @bot.moderation_rewrite(event.message.content, event.user, instructions:) if instructions

    @bot.moderation_rewrite(event.message.content, event.user)
  end

  def response_message(user_id, edited)
    rewritten = edited.to_s.strip
    return "A message from <@#{user_id}> was removed." if rewritten.empty?

    "A message from <@#{user_id}> was rewritten:\n#{rewritten}"
  end
end
