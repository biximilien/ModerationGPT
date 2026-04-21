module ModerationGPT
  class Plugin
    def boot(**); end

    def ready(**); end

    def message(**); end

    def moderation_result(**); end

    def infraction(**); end

    def automod_outcome(**); end

    def rewrite_instructions(**)
      nil
    end

    def moderation_strategies(**)
      []
    end

    def commands
      []
    end
  end
end
