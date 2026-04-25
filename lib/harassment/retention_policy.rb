require "time"

module Harassment
  class RetentionPolicy
    DEFAULT_CONTENT_RETENTION_DAYS = 30

    def initialize(content_retention_days: DEFAULT_CONTENT_RETENTION_DAYS)
      @content_retention_days = positive_integer!(content_retention_days, "content_retention_days")
    end

    def retention_expires_at(timestamp)
      event_time = normalize_time(timestamp, "timestamp")
      event_time + (@content_retention_days * 86_400)
    end

    def redactable?(event, as_of: Time.now.utc)
      event.retention_expired?(as_of:) && !event.redacted?
    end

    private

    def positive_integer!(value, name)
      integer = Integer(value)
      raise ArgumentError, "#{name} must be positive" unless integer.positive?

      integer
    rescue ArgumentError, TypeError
      raise ArgumentError, "#{name} must be positive"
    end

    def normalize_time(value, name)
      case value
      when Time then value.utc
      else
        Time.parse(value.to_s).utc
      end
    rescue ArgumentError
      raise ArgumentError, "#{name} must be a valid time"
    end
  end
end
