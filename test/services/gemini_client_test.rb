# frozen_string_literal: true

require "test_helper"

class GeminiClientTest < ActiveSupport::TestCase
  teardown do
    if defined?(@original_net_http_new)
      Net::HTTP.define_singleton_method(:new, @original_net_http_new)
    end
  end

  test "returns translated text on successful response" do
    response_body = {
      candidates: [
        {
          content: {
            parts: [
              { text: "Hola mundo" }
            ]
          }
        }
      ]
    }.to_json

    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.define_singleton_method(:body) { response_body }

    mock_http = build_mock_http(response)

    @original_net_http_new = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*| mock_http }

    result = GeminiClient.new(api_key: "test_key").prompt("Hello world")

    assert_equal "Hola mundo", result
  end

  test "returns nil on non-OK response" do
    response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
    mock_http = build_mock_http(response)

    @original_net_http_new = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*| mock_http }

    result = GeminiClient.new(api_key: "test_key").prompt("Hello world")

    assert_nil result
  end

  test "returns nil on network error" do
    mock_http = build_error_http

    @original_net_http_new = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*| mock_http }

    result = GeminiClient.new(api_key: "test_key").prompt("Hello world")

    assert_nil result
  end

  test "returns nil when response body has unexpected structure" do
    response_body = { unexpected: "format" }.to_json
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.define_singleton_method(:body) { response_body }

    mock_http = build_mock_http(response)

    @original_net_http_new = Net::HTTP.method(:new)
    Net::HTTP.define_singleton_method(:new) { |*| mock_http }

    result = GeminiClient.new(api_key: "test_key").prompt("Hello world")

    assert_nil result
  end

  private

  def build_mock_http(response)
    Object.new.tap do |mock|
      mock.define_singleton_method(:use_ssl=) { |_val| }
      mock.define_singleton_method(:open_timeout=) { |_val| }
      mock.define_singleton_method(:read_timeout=) { |_val| }
      mock.define_singleton_method(:request) { |_req| response }
    end
  end

  def build_error_http
    Object.new.tap do |mock|
      mock.define_singleton_method(:use_ssl=) { |_val| }
      mock.define_singleton_method(:open_timeout=) { |_val| }
      mock.define_singleton_method(:read_timeout=) { |_val| }
      mock.define_singleton_method(:request) { |_req| raise StandardError, "Connection refused" }
    end
  end
end
