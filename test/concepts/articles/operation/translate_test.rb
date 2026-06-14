# frozen_string_literal: true

require "test_helper"

class Articles::Operation::TranslateTest < ActiveSupport::TestCase
  setup do
    ENV["GEMINI_API_KEY"] = "test_gemini_api_key"
    @article = articles(:draft_article)
  end

  test "translates title and body and persists to database" do
    target_locale = :es
    translated_title = "Título traducido"
    translated_body = "Cuerpo traducido con **markdown**"

    mock_gemini(delimited_response(translated_title, translated_body))

    result = Articles::Operation::Translate.new.call(
      article: @article,
      target_locale: target_locale
    )

    assert_predicate result, :success?

    Mobility.with_locale(target_locale) do
      assert_equal translated_title, @article.title
    end

    translation = @article.article_translations.find_by(locale: target_locale.to_s)

    assert_equal translated_body, translation.content
  ensure
    cleanup_mock_gemini
  end

  test "returns failure when original content is blank" do
    # Bypass validations to blank out title and body
    en_translation = @article.article_translations.find_by!(locale: @article.original_locale)
    en_translation.update_columns(title: "", content: "")

    result = Articles::Operation::Translate.new.call(
      article: @article,
      target_locale: :es
    )

    assert_predicate result, :failure?
    assert_equal "No content to translate", result.failure[:message]
  end

  test "returns failure when GeminiClient returns nil" do
    mock_gemini(nil)

    result = Articles::Operation::Translate.new.call(
      article: @article,
      target_locale: :es
    )

    assert_predicate result, :failure?
    assert_equal "Translation service unavailable. Please try again.", result.failure[:message]
  ensure
    cleanup_mock_gemini
  end

  test "returns failure when response cannot be parsed" do
    mock_gemini("Some random text without delimiters")

    result = Articles::Operation::Translate.new.call(
      article: @article,
      target_locale: :es
    )

    assert_predicate result, :failure?
    assert_equal "Could not parse translated content from API response", result.failure[:message]
  ensure
    cleanup_mock_gemini
  end

  test "persists title only when body delimiters are missing" do
    target_locale = :es
    translated_title = "Solo título traducido"

    mock_gemini(<<~RESPONSE)
      <<<TITLE>>>
      #{translated_title}
      <<<END_TITLE>>>

      <<<BODY>>>
      <<<END_BODY>>>
    RESPONSE

    result = Articles::Operation::Translate.new.call(
      article: @article,
      target_locale: target_locale
    )

    assert_predicate result, :success?

    Mobility.with_locale(target_locale) do
      assert_equal translated_title, @article.title
    end
  ensure
    cleanup_mock_gemini
  end

  test "persists body only when title delimiters are missing" do
    target_locale = :es
    translated_body = "Cuerpo traducido sin título"

    mock_gemini(<<~RESPONSE)
      <<<TITLE>>>
      <<<END_TITLE>>>

      <<<BODY>>>
      #{translated_body}
      <<<END_BODY>>>
    RESPONSE

    result = Articles::Operation::Translate.new.call(
      article: @article,
      target_locale: target_locale
    )

    assert_predicate result, :success?

    translation = @article.article_translations.find_by(locale: target_locale.to_s)

    assert_equal translated_body, translation.content
  ensure
    cleanup_mock_gemini
  end

  test "updates existing translation when already present" do
    target_locale = :es
    translated_title = "Título actualizado"
    translated_body = "Cuerpo actualizado"

    # Create an existing translation first
    @article.article_translations.create!(locale: target_locale.to_s, content: "Viejo cuerpo")

    mock_gemini(delimited_response(translated_title, translated_body))

    result = Articles::Operation::Translate.new.call(
      article: @article,
      target_locale: target_locale
    )

    assert_predicate result, :success?

    Mobility.with_locale(target_locale) do
      assert_equal translated_title, @article.title
    end

    translation = @article.article_translations.find_by(locale: target_locale.to_s)

    assert_equal translated_body, translation.content
    assert_equal 1, @article.article_translations.where(locale: target_locale.to_s).count
  ensure
    cleanup_mock_gemini
  end

  private

  def delimited_response(title, body)
    <<~RESPONSE
      <<<TITLE>>>
      #{title}
      <<<END_TITLE>>>

      <<<BODY>>>
      #{body}
      <<<END_BODY>>>
    RESPONSE
  end

  def mock_gemini(response_value)
    @original_prompt = GeminiClient.instance_method(:prompt)
    GeminiClient.define_method(:prompt) { |_text| response_value }
  end

  def cleanup_mock_gemini
    if @original_prompt
      GeminiClient.define_method(:prompt, @original_prompt)
      @original_prompt = nil
    end
  end
end
