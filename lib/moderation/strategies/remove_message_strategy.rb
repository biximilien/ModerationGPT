require_relative "../strategy"

class RemoveMessageStrategy < ModerationStrategy
  def condition(event)
    flagged?(event, log_label: "Moderation")
  end

  def execute(event)
    reason = "Moderation (removing message)"
    event.message.delete(reason)
    record_infraction(event)
  end
end
