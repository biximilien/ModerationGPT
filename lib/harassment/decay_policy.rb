module Harassment
  class DecayPolicy
    SECONDS_PER_HOUR = 3600.0
    DEFAULT_HALF_LIFE_HOURS = 168.0
    DEFAULT_LAMBDA = Math.log(2) / (DEFAULT_HALF_LIFE_HOURS * SECONDS_PER_HOUR)

    def initialize(lambda_value: DEFAULT_LAMBDA)
      @lambda_value = Float(lambda_value)
      raise ArgumentError, "lambda_value must be non-negative" if @lambda_value.negative?
    end

    def decay(score, from:, to:)
      return Float(score) if from.nil?

      elapsed_seconds = [to.utc - from.utc, 0.0].max
      Float(score) * Math.exp(-@lambda_value * elapsed_seconds)
    end
  end
end
