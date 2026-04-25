module Harassment
  module ClassificationStatus
    PENDING = "pending".freeze
    CLASSIFIED = "classified".freeze
    FAILED_RETRYABLE = "failed_retryable".freeze
    FAILED_TERMINAL = "failed_terminal".freeze

    ALL = [
      PENDING,
      CLASSIFIED,
      FAILED_RETRYABLE,
      FAILED_TERMINAL,
    ].freeze
  end
end
