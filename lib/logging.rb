require "json"
require "logger"
require "time"
require_relative "../environment"

module Logging
  module_function

  def build_logger(io = STDOUT, level: Logger::INFO, format: Environment.log_format)
    logger = Logger.new(io)
    logger.level = level
    logger.formatter = formatter_for(format)
    logger
  end

  def info(event, **fields)
    log(:info, event, **fields)
  end

  def warn(event, **fields)
    log(:warn, event, **fields)
  end

  def error(event, **fields)
    log(:error, event, **fields)
  end

  def formatter_for(format)
    normalized = normalize_format(format)
    normalized == "plain" ? plain_formatter : json_formatter
  end

  def log(level, event, **fields)
    return unless $logger

    payload = { event: event }.merge(compact_fields(fields))
    $logger.public_send(level, payload)
  end

  def compact_fields(fields)
    fields.each_with_object({}) do |(key, value), result|
      result[key] = value unless value.nil?
    end
  end

  def normalize_format(format)
    candidate = format.to_s.downcase
    %w[json plain].include?(candidate) ? candidate : Environment::DEFAULT_LOG_FORMAT
  end

  def json_formatter
    lambda do |severity, time, _progname, msg|
      payload = base_payload(severity, time, msg)
      "#{JSON.generate(payload)}\n"
    end
  end

  def plain_formatter
    lambda do |severity, time, _progname, msg|
      payload = base_payload(severity, time, msg)
      event = payload.delete("event")
      parts = payload.map { |key, value| "#{key}=#{value.inspect}" }
      line = [severity, time.utc.iso8601, event, *parts].compact.join(" ")
      "#{line}\n"
    end
  end

  def base_payload(severity, time, msg)
    payload = {
      "timestamp" => time.utc.iso8601,
      "level" => severity.downcase,
    }

    case msg
    when Hash
      payload.merge(stringify_keys(msg))
    else
      payload.merge("message" => msg.to_s)
    end
  end

  def stringify_keys(hash)
    hash.each_with_object({}) do |(key, value), result|
      result[key.to_s] = value
    end
  end
end
