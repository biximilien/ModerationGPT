module ModerationGPT
  module AI
    class Provider
      def moderate_text(_text, _user = nil)
        raise NotImplementedError, "#{self.class} must implement #moderate_text"
      end

      def moderation_rewrite(_text, _user = nil, instructions:)
        raise NotImplementedError, "#{self.class} must implement #moderation_rewrite"
      end

      def query(_url, _params, _user = nil)
        raise NotImplementedError, "#{self.class} must implement #query"
      end

      def response_text(_response)
        raise NotImplementedError, "#{self.class} must implement #response_text"
      end
    end
  end
end
