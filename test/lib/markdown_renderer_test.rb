require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  setup do
    @previous_public_host = Rails.configuration.x.public_host
    Rails.configuration.x.public_host = "http://lvh.me:3030"
  end

  teardown do
    Rails.configuration.x.public_host = @previous_public_host
  end

  test "image rewrites studio host upload URLs to public host" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("http://studio.lvh.me:3030/u/token123", nil, "example")

    assert_includes html, "http://lvh.me:3030/u/token123"
    refute_includes html, "http://studio.lvh.me:3030/u/token123"
  end

  test "image keeps non-studio URLs unchanged" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("https://cdn.example.com/image.png", nil, "example")

    assert_includes html, "https://cdn.example.com/image.png"
  end

  test "image rewrites studio host URLs without port" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("http://studio.lvh.me/u/token123", nil, "example")

    assert_includes html, "http://lvh.me:3030/u/token123"
  end

  test "image rewrites public lvh upload URL without port" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("http://lvh.me/u/token123", nil, "example")

    assert_includes html, "http://lvh.me:3030/u/token123"
    refute_includes html, "http://lvh.me/u/token123\" alt"
  end

  test "image rewrites relative upload urls" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("/u/token123?variant=thumb", nil, "example")

    assert_includes html, "http://lvh.me:3030/u/token123?variant=thumb"
  end
end
