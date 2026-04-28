require_relative "../strategy"
require_relative "../review_action"

class RemoveMessageStrategy < ModerationStrategy
  def condition(event)
    flagged?(event, log_label: "Moderation")
  end

  def execute(event)
    reason = "Moderation (removing message)"
    if shadow_mode?
      record_review(event, action: Moderation::ReviewAction::WOULD_REMOVE)
      return
    end

    event.message.delete(reason)
    outcome = record_infraction(event)
    record_review(event, action: Moderation::ReviewAction::REMOVED, automod_outcome: outcome_if_automod(outcome))
  end
end
