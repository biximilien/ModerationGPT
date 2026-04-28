require_relative "../strategy"

class RemoveMessageStrategy < ModerationStrategy
  def condition(event)
    flagged?(event, log_label: "Moderation")
  end

  def execute(event)
    reason = "Moderation (removing message)"
    if shadow_mode?
      record_review(event, action: "would_remove")
      return
    end

    event.message.delete(reason)
    outcome = record_infraction(event)
    record_review(event, action: "removed", automod_outcome: outcome_if_automod(outcome))
  end

  private

  def outcome_if_automod(value)
    value.is_a?(String) ? value : nil
  end
end
