# frozen_string_literal: true

require "phlex/test_case"

class Phlex::Shadcn::SheetTest < Phlex::Shadcn::TestCase
  Sheet = Phlex::Shadcn::Sheet

  HELPERS = {
    trigger: Sheet::Trigger, close: Sheet::Close, content: Sheet::Content, header: Sheet::Header,
    footer: Sheet::Footer, title: Sheet::Title, description: Sheet::Description
  }.freeze

  def render_view(&block)
    Class.new(Phlex::HTML) { define_method(:view_template, &block) }.new.call
  end

  def fragment(html) = Nokogiri::HTML5.fragment(html)

  def sheet(root: {}, content: {})
    render_view do
      render(Sheet.new(**root)) do
        render(Sheet::Trigger.new) { "Open" }
        render(Sheet::Content.new(**content)) do
          render(Sheet::Title.new) { "Title" }
          render(Sheet::Description.new) { "Description" }
        end
      end
    end
  end

  test "host carries the controller and the closed parts live in a template" do
    doc = fragment(sheet)
    host = doc.at_css("[data-controller=shadcn--sheet]")

    assert_equal "display: contents", host["style"]
    assert_nil host["data-slot"]
    assert_equal "false", host["data-shadcn--sheet-open-value"]
    assert_equal 1, host.css("[data-slot=sheet-content]").size
    assert host.at_css("template [data-slot=sheet-overlay]")
    assert_equal "sheet-trigger", host.at_css("button")["data-slot"]
  end

  test "each side maps to its classes and an unknown side raises" do
    { "right" => "right-0", "left" => "left-0", "top" => "top-0", "bottom" => "bottom-0" }.each do |side, token|
      assert_includes fragment(sheet(content: { side: side.to_sym })).at_css("[data-slot=sheet-content]")["class"], token
    end
    assert_raises(ArgumentError) { sheet(content: { side: "middle" }) }
  end

  test "x close has no data-slot, content merges class and aria ids" do
    doc = fragment(sheet(content: { class: "w-96", aria: { describedby: "x" } }))
    content = doc.at_css("[data-slot=sheet-content]")

    assert_includes content["class"], "w-96"
    assert_equal "x sheet-1-description", content["aria-describedby"]
    assert_equal "sheet-1-title", content["aria-labelledby"]
    close = content.at_css("button")

    assert_nil close["data-slot"]
    assert_equal "Close", close.at_css(".sr-only").text
  end

  test "every DX helper renders the same HTML as the explicit class" do
    HELPERS.each do |name, klass|
      explicit = render_view { render(Sheet.new) { render(Sheet::Content.new) { render(klass.new) { "x" } } } }
      helper = render_view { render(Sheet.new) { |s| s.content { s.public_send(name) { "x" } } } }

      assert_equal explicit, helper, name.to_s
    end
  end

  test "every root and part keyword is accepted and rendered" do
    out = render_view do
      render(Sheet.new(open: false, default_open: true, modal: false, class: "x-root", data: { foo: "bar" })) do
        render(Sheet::Trigger.new(as_child: false, id: "t")) { "Open" }
        render(Sheet::Portal.new) { "" }
        render(Sheet::Content.new(side: :left, show_close_button: false, close_label: "Fermer", force_mount: true, as_child: false, class: "x-content")) do
          render(Sheet::Header.new(class: "h")) { "H" }
          render(Sheet::Title.new(as_child: false, class: "ti")) { "T" }
          render(Sheet::Description.new(as_child: false, class: "d")) { "D" }
          render(Sheet::Overlay.new(force_mount: true, as_child: false, class: "o"))
          render(Sheet::Close.new(as_child: false, class: "c")) { "C" }
          render(Sheet::Footer.new(class: "f")) { "F" }
        end
      end
    end

    assert_includes out, "x-root"
    assert_includes out, "x-content"
  end

  test "parts raise a clear ArgumentError outside the root" do
    %i[Trigger Content Overlay Portal Title Description].each do |part|
      error = assert_raises(ArgumentError, part.to_s) { render_view { render(Sheet.const_get(part).new) } }

      assert_match(/must be used within Sheet/, error.message, part.to_s)
    end
  end

  test "the root lists every generated helper" do
    %i[trigger close portal overlay content header footer title description].each do |name|
      assert Sheet.public_method_defined?(name), "missing helper ##{name}"
    end
  end

  test "as_child renders the trigger onto the given element" do
    out = render_view do
      render(Sheet.new) do
        render(Sheet::Trigger.new(as_child: :a, href: "/x", class: "t")) { "Open" }
      end
    end
    trigger = Nokogiri::HTML5.fragment(out).at_css("[data-slot*=trigger]")

    assert_equal "a", trigger.name
    assert_equal "/x", trigger["href"]
    assert_includes trigger["class"], "t"
  end

  test "an unknown side names the accepted ones" do
    error = assert_raises(ArgumentError) { Sheet::Content.new(side: "middle") }

    assert_match(/side must be one of right, left, top, bottom, got "middle"/, error.message)
  end
end
