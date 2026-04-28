require "json"
require "net/http"
require "uri"
require_relative "../../environment"
require_relative "../telemetry"

module GoogleAI
  class Transport
    API_ROOT = "https://generativelanguage.googleapis.com/v1beta".freeze

    def initialize(api_key: Environment.google_ai_api_key)
      @api_key = api_key
    end

    def generate_content(model:, payload:, user: nil)
      url = "#{API_ROOT}/models/#{model}:generateContent"
      Telemetry.in_span(url, attributes: telemetry_attributes(url, user)) do |span|
        begin
          response = post_json(url, payload, span)
          parsed = JSON.parse(response.body)
          raise "Google AI API error: #{parsed['error']}" if parsed.include?("error")
          raise "Google AI API error: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          parsed
        rescue JSON::ParserError => e
          span.add_event("Google AI API invalid JSON", attributes: { "exception.message" => e.message })
          raise "Google AI API returned invalid JSON"
        rescue Net::ReadTimeout, Net::OpenTimeout => e
          span.add_event("Google AI API timeout", attributes: { "exception.message" => e.message })
          raise "Google AI API timeout"
        end
      end
    end

    private

    def post_json(url, payload, span)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["x-goog-api-key"] = @api_key
      request.body = payload.to_json
      span.add_event("Google AI API call")

      response = http.request(request)
      span.set_attribute("http.status_code", response.code.to_i)
      span.add_event("Google AI API response")
      response
    end

    def telemetry_attributes(url, user)
      uri = URI.parse(url)
      {
        "http.url" => url,
        "http.scheme" => "https",
        "http.target" => uri.request_uri,
        "http.method" => "POST",
        "net.peer.name" => uri.host,
        "net.peer.port" => uri.port,
        "discord.user.hash" => anonymized_user_hash(user),
        "discord.user.bot_account" => user&.bot_account,
      }
    end

    def anonymized_user_hash(user)
      return nil unless user

      Telemetry::Anonymizer.hash(user.id)
    end
  end
end
