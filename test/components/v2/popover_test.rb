# frozen_string_literal: true

require "test_helper"

class Components::V2::PopoverTest < ActiveSupport::TestCase
  Popover = Components::V2::Popover

  def render_popover(root: {}, trigger: {}, content: {}, &block)
    Class.new(Components::Base) do
      define_method(:view_template) do
        render Popover.new(**root) do
          render Popover::Trigger.new(**trigger) { plain "Open" }
          render Popover::Content.new(**content), &(block || proc { plain "Body" })
        end
      end
    end.new.call
  end

  test "closed trigger hosts the controller with button aria" do
    out = render_popover

    assert_match(/<button [^>]*data-slot="popover-trigger"/, out)
    assert_includes out, 'aria-haspopup="dialog"'
    assert_includes out, 'aria-expanded="false"'
    assert_includes out, 'data-state="closed"'
    assert_includes out, 'data-controller="v2--popover"'
    assert_not_includes out, "aria-controls"
  end

  test "open state adds aria-controls" do
    out = render_popover(root: { default_open: true })

    assert_includes out, 'aria-expanded="true"'
    assert_match(/aria-controls="popover-\d+-content"/, out)
  end

  test "content ships in an inert template with oracle classes and merged class" do
    out = render_popover(content: { class: "w-80", side: :left, dir: "rtl", data: { foo: "bar" } })

    assert_match(/<template [^>]*data-v2--popover-template="popover-\d+"/, out)
    assert_includes out, 'role="dialog"'
    assert_includes out, 'data-slot="popover-content"'
    assert_includes out, "w-80"
    assert_not_includes out, "w-72"
    assert_includes out, 'data-foo="bar"'
    assert_includes out, "&quot;side&quot;:&quot;left&quot;"
    assert_includes out, "--radix-popover-trigger-width: var(--radix-popper-anchor-width)"
  end

  test "content hosts the controller when no trigger precedes it" do
    out = Class.new(Components::Base) do
      define_method(:view_template) do
        render(Popover.new(open: true)) do
          render(Popover::Anchor.new(class: "h-10")) { plain "a" }
          render(Popover::Content.new) { plain "Body" }
        end
      end
    end.new.call

    assert_match(/<template [^>]*data-controller="v2--popover"/, out)
    assert_includes out, 'data-slot="popover-anchor"'
    assert_includes out, 'data-v2--popover-controlled-value="true"'
  end

  test "as_child and disabled on the trigger" do
    out = render_popover(trigger: { as_child: :a, href: "#", disabled: true })

    assert_match(/<a .*href="#" disabled>/, out)
    assert_includes out, 'data-slot="popover-trigger"'
  end

  test "header title and description" do
    out = Class.new(Components::Base) do
      define_method(:view_template) do
        render(Popover::Header.new(class: "x")) { plain "h" }
        render(Popover::Title.new) { plain "t" }
        render(Popover::Description.new) { plain "d" }
      end
    end.new.call

    assert_includes out, 'class="flex flex-col gap-1 text-sm x"'
    assert_includes out, '<div class="font-medium" data-slot="popover-title">'
    assert_includes out, "<p "
    assert_includes out, "text-muted-foreground"
  end

  test "every DX helper renders the same HTML as the explicit call" do
    helpers = Class.new(Components::Base) do
      define_method(:view_template) do
        render(Popover.new) do |popover|
          popover.trigger { plain "Open" }
          popover.anchor { plain "A" }
          popover.content do
            popover.header { popover.title { plain "T" } }
            popover.description { plain "D" }
          end
        end
      end
    end.new.call
    explicit = Class.new(Components::Base) do
      define_method(:view_template) do
        render(Popover.new) do
          render(Popover::Trigger.new) { plain "Open" }
          render(Popover::Anchor.new) { plain "A" }
          render(Popover::Content.new) do
            render(Popover::Header.new) { render(Popover::Title.new) { plain "T" } }
            render(Popover::Description.new) { plain "D" }
          end
        end
      end
    end.new.call

    %i[trigger content anchor header title description].each { |name| assert_respond_to Popover.new, name }
    assert_equal explicit.gsub(/popover-\d+/, "popover-N"), helpers.gsub(/popover-\d+/, "popover-N")
  end
end
