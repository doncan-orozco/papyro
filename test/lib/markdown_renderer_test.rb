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

    assert_includes html, "\"/u/token123\""
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

    assert_includes html, "\"/u/token123\""
  end

  test "image rewrites public lvh upload URL without port" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("http://lvh.me/u/token123", nil, "example")

    assert_includes html, "\"/u/token123\""
    refute_includes html, "http://lvh.me/u/token123\" alt"
  end

  test "image rewrites relative upload urls" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("/u/token123?variant=thumb", nil, "example")

    assert_includes html, "\"/u/token123?variant=thumb\""
  end

  test "image wraps img with lightbox link attributes" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("/u/token123", "preview", "example")

    assert_includes html, "<a"
    assert_includes html, "href=\"/u/token123\""
    assert_includes html, "data-action=\"lightbox#open:prevent\""
    assert_includes html, "data-lightbox-url-value=\"/u/token123?disposition=attachment\""
    assert_includes html, "<img"
    assert_includes html, "title=\"preview\""
  end

  test "image escapes alt, title and url attributes" do
    renderer = MarkdownRenderer.new(ActionText::Markdown::DEFAULT_RENDERER_OPTIONS)

    html = renderer.image("/u/t\"onmouseover=\"x", "t\"onfocus=\"x", "a\"onerror=\"x")

    image = Nokogiri::HTML5.fragment(html).at_css("img")

    assert_equal "a\"onerror=\"x", image["alt"]
    assert_nil image["onerror"]
    assert_nil image["onfocus"]
    assert_nil image["onmouseover"]
  end

  test "render removes script tags" do
    html = MarkdownRenderer.render("Hello\n\n<script>alert(1)</script>")

    assert_includes html, "Hello"
    refute_includes html, "<script"
  end

  test "render removes event handler attributes from raw html" do
    html = MarkdownRenderer.render("<img src=\"/x.png\" onerror=\"alert(1)\">")

    refute_includes html, "onerror"
  end

  test "render removes javascript links" do
    html = MarkdownRenderer.render("[click](javascript:alert(1)) <a href=\"javascript:alert(2)\">raw</a>")

    refute_includes html, "javascript:"
  end

  test "render removes iframes and forms" do
    html = MarkdownRenderer.render("<iframe src=\"https://evil.example\"></iframe><form action=\"https://evil.example\"><input name=\"q\"></form>")

    refute_includes html, "<iframe"
    refute_includes html, "<form"
    refute_includes html, "<input"
  end

  test "render removes stimulus wiring written in raw html" do
    html = MarkdownRenderer.render("<a href=\"/\" data-action=\"click->session#destroy\" data-controller=\"session\">x</a>")

    refute_includes html, "data-action"
    refute_includes html, "data-controller"
  end

  test "render removes a lightbox url that is not a path or http url" do
    html = MarkdownRenderer.render("<a href=\"/\" data-action=\"lightbox#open:prevent\" data-lightbox-url-value=\"javascript:alert(1)\">x</a>")

    refute_includes html, "javascript:"
  end

  test "render neutralizes attribute injection through image alt text" do
    html = MarkdownRenderer.render("![a\" onerror=\"alert(1)](/u/token123)")

    image = Nokogiri::HTML5.fragment(html).at_css("img")

    assert_nil image["onerror"]
  end

  test "render keeps the image lightbox wiring" do
    html = MarkdownRenderer.render("![example](/u/token123)")

    link = Nokogiri::HTML5.fragment(html).at_css("a")

    assert_equal "lightbox#open:prevent", link["data-action"]
    assert_equal "/u/token123?disposition=attachment", link["data-lightbox-url-value"]
    assert_equal "example", link.at_css("img")["alt"]
  end

  test "render keeps tables with column alignment" do
    html = MarkdownRenderer.render("| Name | Count |\n|:-----|------:|\n| a | 1 |")

    cell = Nokogiri::HTML5.fragment(html).at_css("table tbody td:last-child")

    assert_equal "1", cell.text
    assert_match(/text-align:\s*right/, cell["style"])
  end

  test "render keeps heading anchors" do
    html = MarkdownRenderer.render("## Getting started")

    heading = Nokogiri::HTML5.fragment(html).at_css("h2")

    assert_equal "getting-started", heading["id"]
    assert_equal "#getting-started", heading.at_css("a.heading__link")["href"]
    assert_equal "true", heading.at_css("a.heading__link")["aria-hidden"]
  end

  test "render keeps highlighted code blocks" do
    html = MarkdownRenderer.render("```ruby\nputs 1\n```")

    assert Nokogiri::HTML5.fragment(html).at_css("pre.highlight span")
  end

  test "build returns a renderer whose output is sanitized" do
    html = MarkdownRenderer.build.render("<script>alert(1)</script>")

    refute_includes html, "<script"
  end
end
