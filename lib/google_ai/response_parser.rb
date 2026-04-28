module GoogleAI
  class ResponseParser
    def self.text(response)
      response.fetch("candidates", []).flat_map do |candidate|
        candidate.fetch("content", {}).fetch("parts", []).map { |part| part["text"] }
      end.compact.join.strip
    end
  end
end
