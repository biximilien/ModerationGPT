require "dotenv"
Dotenv.load

module Environment
  REQUIRED_VARIABLES = %w[
    DISCORD_BOT_TOKEN
    REDIS_URL
  ].freeze
  AI_PROVIDER_API_KEYS = {
    "openai" => "OPENAI_API_KEY",
    "google_ai" => "GOOGLE_AI_API_KEY",
  }.freeze

  DEFAULT_OPENAI_MODERATION_MODEL = "omni-moderation-latest"
  DEFAULT_OPENAI_REWRITE_MODEL = "gpt-4.1-mini"
  DEFAULT_GOOGLE_AI_MODEL = "gemini-2.5-flash"
  DEFAULT_KARMA_AUTOMOD_THRESHOLD = -5
  DEFAULT_TELEMETRY_HASH_SALT = "development-telemetry-salt"
  DEFAULT_KARMA_AUTOMOD_ACTION = "timeout"
  DEFAULT_KARMA_TIMEOUT_SECONDS = 3_600
  DEFAULT_PERSONALITY = "objective"
  DEFAULT_LOG_FORMAT = "json"
  DEFAULT_HARASSMENT_CLASSIFIER_MODEL = "gpt-4o-2024-08-06"
  DEFAULT_HARASSMENT_CLASSIFIER_CACHE_TTL_SECONDS = 3_600
  DEFAULT_HARASSMENT_CLASSIFIER_RATE_LIMIT_PER_MINUTE = 30
  DEFAULT_HARASSMENT_STORAGE_BACKEND = "redis"

  def self.validate!
    required = REQUIRED_VARIABLES + [ai_api_key_variable]
    missing = required.select { |name| missing?(ENV[name]) }
    return if missing.empty?

    raise "Missing required environment variables: #{missing.join(', ')}"
  end

  def self.openai_api_key
    ENV["OPENAI_API_KEY"]
  end

  def self.discord_bot_token
    ENV["DISCORD_BOT_TOKEN"]
  end

  def self.redis_url
    ENV["REDIS_URL"]
  end

  def self.database_url
    ENV["DATABASE_URL"]
  end

  def self.openai_moderation_model
    ENV.fetch("OPENAI_MODERATION_MODEL", DEFAULT_OPENAI_MODERATION_MODEL)
  end

  def self.openai_rewrite_model
    ENV.fetch("OPENAI_REWRITE_MODEL", DEFAULT_OPENAI_REWRITE_MODEL)
  end

  def self.google_ai_api_key
    ENV["GOOGLE_AI_API_KEY"]
  end

  def self.google_ai_model
    ENV.fetch("GOOGLE_AI_MODEL", DEFAULT_GOOGLE_AI_MODEL)
  end

  def self.karma_automod_threshold
    ENV.fetch("KARMA_AUTOMOD_THRESHOLD", DEFAULT_KARMA_AUTOMOD_THRESHOLD).to_i
  end

  def self.telemetry_hash_salt
    ENV.fetch("TELEMETRY_HASH_SALT", DEFAULT_TELEMETRY_HASH_SALT)
  end

  def self.telemetry_enabled?
    ENV.fetch("TELEMETRY_ENABLED", "false").casecmp("true").zero?
  end

  def self.enabled_plugins
    ENV.fetch("PLUGINS", "").split(",").map(&:strip).reject(&:empty?).uniq
  end

  def self.plugin_requires
    ENV.fetch("PLUGIN_REQUIRES", "").split(",").map(&:strip).reject(&:empty?)
  end

  def self.personality
    ENV.fetch("PERSONALITY", DEFAULT_PERSONALITY).downcase
  end

  def self.karma_automod_action
    ENV.fetch("KARMA_AUTOMOD_ACTION", DEFAULT_KARMA_AUTOMOD_ACTION)
  end

  def self.karma_timeout_seconds
    ENV.fetch("KARMA_TIMEOUT_SECONDS", DEFAULT_KARMA_TIMEOUT_SECONDS).to_i
  end

  def self.log_invite_url?
    ENV.fetch("LOG_INVITE_URL", "false").casecmp("true").zero?
  end

  def self.log_format
    candidate = ENV.fetch("LOG_FORMAT", DEFAULT_LOG_FORMAT).downcase
    %w[json plain].include?(candidate) ? candidate : DEFAULT_LOG_FORMAT
  end

  def self.harassment_classifier_model
    return ENV["HARASSMENT_CLASSIFIER_MODEL"] unless missing?(ENV["HARASSMENT_CLASSIFIER_MODEL"])
    return google_ai_model if effective_ai_provider == "google_ai"

    DEFAULT_HARASSMENT_CLASSIFIER_MODEL
  end

  def self.harassment_classifier_cache_ttl_seconds
    ENV.fetch("HARASSMENT_CLASSIFIER_CACHE_TTL_SECONDS", DEFAULT_HARASSMENT_CLASSIFIER_CACHE_TTL_SECONDS).to_i
  end

  def self.harassment_classifier_rate_limit_per_minute
    ENV.fetch("HARASSMENT_CLASSIFIER_RATE_LIMIT_PER_MINUTE", DEFAULT_HARASSMENT_CLASSIFIER_RATE_LIMIT_PER_MINUTE).to_i
  end

  def self.harassment_storage_backend
    candidate = ENV.fetch("HARASSMENT_STORAGE_BACKEND", DEFAULT_HARASSMENT_STORAGE_BACKEND).downcase
    %w[redis postgres].include?(candidate) ? candidate : DEFAULT_HARASSMENT_STORAGE_BACKEND
  end

  def self.missing?(value)
    value.nil? || value.strip.empty?
  end

  def self.effective_ai_provider
    enabled_plugins.reverse_each do |plugin|
      return plugin if AI_PROVIDER_API_KEYS.key?(plugin)
    end

    "openai"
  end

  def self.ai_api_key_variable
    AI_PROVIDER_API_KEYS.fetch(effective_ai_provider)
  end

  private_class_method :missing?, :effective_ai_provider, :ai_api_key_variable
end
