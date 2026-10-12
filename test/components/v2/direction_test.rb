# frozen_string_literal: true

require "test_helper"

class Components::V2::DirectionTest < ActiveSupport::TestCase
  class Probe < Components::V2::Base
    include Components::V2::Direction::Consumer

    def initialize(dir: nil)
      @dir = dir
      super()
    end

    def view_template
      span { use_direction(@dir) }
    end
  end

  class Page < Components::V2::Base
    def view_template
      render Probe.new
      render Components::V2::Direction::Provider.new(direction: :rtl) do
        render Probe.new
        render Probe.new(dir: "ltr")
        render Components::V2::Direction::Provider.new(dir: nil) { render Probe.new }
      end
      render Probe.new
    end
  end

  test "provider renders no markup and scopes the value" do
    assert_equal "<span>ltr</span><span>rtl</span><span>ltr</span><span>ltr</span><span>ltr</span>", Page.new.call
  end

  test "direction wins over dir" do
    html = Components::V2::Direction::Provider.new(dir: "ltr", direction: "rtl").call { "x" }

    assert_equal "x", html
  end

  test "rejects invalid values" do
    assert_raises(ArgumentError) { Components::V2::Direction::Provider.new(dir: "up") }
  end
end
