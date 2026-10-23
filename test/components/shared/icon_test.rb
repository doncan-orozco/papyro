require "test_helper"

class Components::Shared::IconTest < ActiveSupport::TestCase
  # every icon name the host and the papyro_studio engine render, spelled as their callers spell it
  CATALOG_NAMES = {
    check: "check",
    search: "search",
    link: "link",
    "chevron-down": "chevron-down",
    chevron_down: "chevron-down",
    "chevron-left": "chevron-left",
    "more-horizontal": "ellipsis",
    arrow_left: "arrow-left",
    maximize: "maximize",
    plus: "plus",
    alert_circle: "circle-alert",
    alert_triangle: "triangle-alert",
    home: "house"
  }.freeze

  LUCIDE_NAMES = {
    camera: "camera",
    globe: "globe",
    languages: "languages",
    linkedin: "linkedin",
    map_pin: "map-pin",
    menu: "menu",
    monitor: "monitor",
    moon: "moon",
    sparkles: "sparkles",
    sun: "sun",
    twitter: "twitter",
    check_circle_2: "check-circle-2",
    circle_dashed: "circle-dashed"
  }.freeze

  test "catalog icons render the chadcn markup" do
    CATALOG_NAMES.each do |name, key|
      assert_equal render_chadcn(key), render_icon(name), "icon #{name.inspect}"
    end
  end

  test "other icons render lucide-rails paths with the lucide classes" do
    LUCIDE_NAMES.each do |name, key|
      svg = Nokogiri::HTML5.fragment(render_icon(name)).at_css("svg")

      assert_equal "lucide lucide-#{key}", svg["class"], "icon #{name.inspect}"
      assert_equal "true", svg["aria-hidden"]
      assert_equal "currentColor", svg["stroke"]
      assert_equal "0 0 24 24", svg["viewbox"]
      assert_equal Nokogiri::HTML5.fragment(LucideRails::IconProvider.icon(key)).to_html, svg.inner_html
    end
  end

  test "renders no size class of its own" do
    (CATALOG_NAMES.keys + LUCIDE_NAMES.keys).each do |name|
      classes = Nokogiri::HTML5.fragment(render_icon(name)).at_css("svg")["class"].split

      assert_empty classes.grep(/\A(size|h|w)-/), "icon #{name.inspect}"
    end
  end

  test "merges caller classes and attributes on both paths" do
    [ :check, :sun ].each do |name|
      svg = Nokogiri::HTML5.fragment(render_icon(name, class: "size-4 text-muted-foreground", data: { role: "x" })).at_css("svg")

      assert_includes svg["class"], "size-4 text-muted-foreground"
      assert_equal "x", svg["data-role"]
    end
  end

  test "size sets width and height" do
    [ :check, :camera ].each do |name|
      svg = Nokogiri::HTML5.fragment(render_icon(name, size: 16)).at_css("svg")

      assert_equal [ "16", "16" ], [ svg["width"], svg["height"] ]
    end
  end

  test "an unknown name raises" do
    assert_raises(ArgumentError) { render_icon(:not_an_icon_anywhere) }
  end

  private

  def render_icon(name, **attrs)
    ApplicationController.render(Components::Shared::Icon.new(name, **attrs), layout: false)
  end

  def render_chadcn(key)
    ApplicationController.render(Chadcn::Icon.new(key), layout: false)
  end
end
