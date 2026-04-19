require_relative "../environment"

class ModerationStrategy
  def initialize(bot)
    @bot = bot
  end

  def condition(event)
    false
  end

  def execute(event)
    nil
  end

  private

  def record_infraction(event)
    score = @bot.decrement_user_karma(event.server.id, event.user.id)
    $logger.info("Karma score for #{event.user.id}: #{score}")

    if score <= Environment.karma_automod_threshold
      $logger.warn("User #{event.user.id} reached automated moderation threshold with karma #{score}")
    end

    score
  end
end

class RemoveMessageStrategy < ModerationStrategy
  def condition(event)
    result = @bot.moderate_text(event.message.content, event.user)
    $logger.info("Moderation flagged: #{result.flagged}")
    result.flagged
  end

  def execute(event)
    reason = "Moderation (removing message)"
    event.message.delete(reason)
    record_infraction(event)
  end
end

class WatchListStrategy < ModerationStrategy
  def condition(event)
    return false unless @bot.get_watch_list_users(event.server.id.to_i).include?(event.user.id.to_i)

    result = @bot.moderate_text(event.message.content, event.user)
    $logger.info("Watch list moderation flagged: #{result.flagged}")
    result.flagged
  end

  def execute(event)
    edited = @bot.moderation_rewrite(event.message.content, event.user)
    $logger.info(edited)
    reason = "Moderation (rewriting due to negative sentiment)"
    event.message.delete(reason)
    record_infraction(event)
    event.respond(response_message(event.user.id, edited))
  end

  private

  def response_message(user_id, edited)
    rewritten = edited.to_s.strip
    return "A message from <@#{user_id}> was removed." if rewritten.empty?

    "A message from <@#{user_id}> was rewritten:\n#{rewritten}"
  end
end
