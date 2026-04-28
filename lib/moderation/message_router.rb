require_relative "../logging"

module Moderation
  class MessageRouter
    def initialize(strategies)
      @strategies = strategies
    end

    def handle(event)
      @strategies.any? do |strategy|
        execute_strategy?(strategy, event)
      end
    end

    private

    def execute_strategy?(strategy, event)
      return false unless strategy.condition(event)

      strategy.execute(event)
      true
    rescue StandardError => e
      Logging.error("moderation_strategy_failed", strategy: strategy.class.name, error_class: e.class.name,
                                                  error_message: e.message)
      false
    end
  end
end
