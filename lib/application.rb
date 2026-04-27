require_relative "backend"
require_relative "open_ai"

module ModerationGPT
  class Application
    include Backend
    include OpenAI

    def initialize
      initialize_backend
    end
  end
end
