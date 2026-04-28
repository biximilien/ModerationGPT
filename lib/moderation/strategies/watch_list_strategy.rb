require_relative "../strategy"
require_relative "../review_action"

class WatchListStrategy < ModerationStrategy
  def condition(event)
    return false unless watched_user?(event)

    flagged?(event, log_label: "Watch list moderation")
  end

  def execute(event)
    edited = shadow_mode? && !shadow_rewrite? ? nil : moderation_rewrite(event)
    reason = "Moderation (rewriting due to negative sentiment)"
    if shadow_mode?
      record_review(event, action: Moderation::ReviewAction::WOULD_REWRITE, rewrite: edited)
      return
    end

    event.message.delete(reason)
    outcome = record_infraction(event)
    event.respond(response_message(event.user.id, edited))
    record_review(event, action: Moderation::ReviewAction::REWRITTEN, rewrite: edited, automod_outcome: outcome_if_automod(outcome))
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
