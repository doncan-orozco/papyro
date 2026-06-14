# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class GeminiClient
  ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent"

  def initialize
    @api_key = ENV.fetch("GEMINI_API_KEY")
  end

  def prompt(text)
    uri = URI(ENDPOINT)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = @api_key
    request.body = {
      contents: [ { parts: [ { text: text } ] } ]
    }.to_json

    response = http.request(request)

    return nil unless response.is_a?(Net::HTTPOK)

    JSON.parse(response.body).dig("candidates", 0, "content", "parts", 0, "text")
  rescue StandardError => e
    Rails.logger.error("GeminiClient error: #{e.message}")
    nil
  end
end
