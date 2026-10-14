# frozen_string_literal: true

require "phlex/test_case"

class Phlex::Shadcn::PopoverTest < Phlex::Shadcn::TestCase
  Popover = Phlex::Shadcn::Popover

  def render_popover(root: {}, trigger: {}, content: {}, &block)
    Class.new(Phlex::HTML) do
      define_method(:view_template) do
        render Popover.new(**root) do
          render Popover::Trigger.new(**trigger) { plain "Open" }
          render Popover::Content.new(**content), &block || proc { plain "Body" }
        end
      end
    end.new.call
  end

  test "closed trigger hosts the controller and content ships in a template" do
    out = render_popover

    assert_includes out, 'data-slot="popover-trigger"'
    assert_includes out, 'aria-haspopup="dialog"'
    assert_includes out, 'aria-expanded="false"'
    assert_includes out, 'data-controller="shadcn--popover"'
    assert_match(/<template data-shadcn--popover-template="popover-\d+"/, out)
    assert_includes out, 'data-slot="popover-content"'
    assert_includes out, 'role="dialog"'
  end

  test "default_open renders aria-controls and open state" do
    out = render_popover(root: { default_open: true })

    assert_includes out, 'aria-expanded="true"'
    assert_match(/aria-controls="popover-\d+-content"/, out)
  end

  # Radix spreads contentProps after the generated id (the trigger's aria-controls keeps the generated one).
  test "a caller id replaces the generated content id but not the trigger's aria-controls" do
    out = render_popover(root: { default_open: true }, content: { id: "mine" })

    assert_includes out, '<div id="mine"'
    assert_match(/aria-controls="popover-\d+-content"/, out)
    refute_match(/id="popover-\d+-content"/, out)
  end

  test "merges class and passes attrs through" do
    out = render_popover(trigger: { data: { foo: "bar" } }, content: { class: "w-80", side: :top })

    assert_includes out, 'data-foo="bar"'
    assert_includes out, "w-80"
    assert_includes out, "&quot;side&quot;:&quot;top&quot;"
  end

  test "every DX helper renders the same HTML as the explicit call" do
    root = Popover.new

    %i[trigger content anchor header title description].each { |name| assert_respond_to root, name }

    helper = Class.new(Phlex::HTML) do
      def view_template
        render Popover.new do |popover|
          popover.header { popover.title { "T" } }
          popover.description { "D" }
        end
      end
    end.new.call
    explicit = Class.new(Phlex::HTML) do
      def view_template
        render Popover.new do
          render(Popover::Header.new { render(Popover::Title.new { "T" }) })
          render(Popover::Description.new { "D" })
        end
      end
    end.new.call

    assert_equal explicit, helper
  end

  test "every root and part keyword is accepted" do
    out = Class.new(Phlex::HTML) do
      define_method(:view_template) do
        render Popover.new(open: false, default_open: true, modal: true) do
          render Popover::Anchor.new(as_child: false, class: "x-anchor") { "A" }
          render Popover::Trigger.new(as_child: false, class: "x-trigger") { "T" }
          render Popover::Content.new(side: :top, side_offset: 8, align: :start, align_offset: 2, avoid_collisions: false, collision_padding: 4, collision_boundary: "#b", arrow_padding: 3, sticky: :always, hide_when_detached: true, update_position_strategy: :always, force_mount: true, class: "x-content") do
            render(Popover::Header.new(class: "x-header")) { "H" }
          end
        end
      end
    end.new.call

    %w[x-anchor x-trigger x-content x-header].each { |token| assert_includes out, token }
    assert_includes out, "&quot;sideOffset&quot;:8"
    assert_includes out, "&quot;sticky&quot;:&quot;always&quot;"
  end

  test "parts that need the root raise a clear ArgumentError outside it" do
    %i[Trigger Anchor Content].each do |part|
      error = assert_raises(ArgumentError, part.to_s) { Popover.const_get(part).new.call }

      assert_match(/must be used within Popover/, error.message, part.to_s)
    end
  end

  test "the root lists its generated helpers" do
    %i[trigger anchor content header title description].each do |name|
      assert Popover.public_method_defined?(name), "missing helper ##{name}"
    end
  end

  test "as_child renders the trigger onto the given element" do
    out = render_popover(trigger: { as_child: :a, href: "/x", class: "t" })

    assert_match(/<a [^>]*data-slot="popover-trigger"/, out)
    assert_includes out, 'href="/x"'
  end
end
