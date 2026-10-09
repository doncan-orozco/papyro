require "test_helper"
require "tmpdir"
require "stringio"

class Shadcn::ThemeTest < ActiveSupport::TestCase
  HSL_THEME = <<~CSS
    :root {
      --background: 0 0% 100%;
      --foreground: 240 10% 3.9%;
      --primary: 240 5.9% 10%;
      --primary-foreground: 0 0% 98%;
      --radius: 0.5rem;
    }
    .dark {
      --background: 240 10% 3.9%;
      --foreground: 0 0% 98%;
    }
  CSS

  setup do
    @original_dir = Shadcn::Theme.dir
    @tmp = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@tmp, "presets"))
    FileUtils.cp(Rails.root.join("app/assets/tailwind/theme/theme.css"), File.join(@tmp, "theme.css"))
    %w[zinc slate].each { |n| FileUtils.cp(Rails.root.join("app/assets/tailwind/theme/presets/#{n}.css"), File.join(@tmp, "presets")) }
    Shadcn::Theme.dir = @tmp
  end

  teardown do
    Shadcn::Theme.dir = @original_dir
    FileUtils.remove_entry(@tmp)
  end

  test "contrast of white on black is 21:1 and of equal colors is 1:1" do
    assert_in_delta 21.0, Shadcn::Theme.contrast("oklch(1 0 0)", "oklch(0 0 0)"), 0.05
    assert_in_delta 1.0, Shadcn::Theme.contrast("oklch(0.5 0 0)", "oklch(0.5 0 0)"), 0.001
    assert_in_delta 21.0, Shadcn::Theme.contrast("#ffffff", "#000000"), 0.05
  end

  test "colors with alpha are skipped by the contrast check" do
    assert_nil Shadcn::Theme.contrast("oklch(1 0 0 / 10%)", "oklch(0 0 0)")
  end

  test "shipped theme and every preset are valid" do
    assert_empty Shadcn::Theme.check[:errors]
    Shadcn::Theme.presets.each do |name|
      palette = Shadcn::Theme.parse(File.read(File.join(@tmp, "presets", "#{name}.css")))

      assert_empty Shadcn::Theme.validate(palette)[:errors], name
    end
  end

  test "use switches the colors and keeps the rest of the file" do
    Shadcn::Theme.use("slate")

    css = File.read(Shadcn::Theme.theme_file)

    assert_includes css, "source: preset slate"
    assert_includes css, "theme:brand:start"
    assert_equal Shadcn::Theme.parse(File.read(File.join(@tmp, "presets", "slate.css"))).root, Shadcn::Theme.parse(css).root
  end

  test "use rejects an unknown preset listing the available ones" do
    error = assert_raises(Shadcn::Theme::Error) { Shadcn::Theme.use("nope") }

    assert_includes error.message, "slate"
  end

  test "import wraps legacy bare HSL triplets and fills missing variables from the current theme" do
    result = Shadcn::Theme.import("-", input: StringIO.new(HSL_THEME))

    css = File.read(Shadcn::Theme.theme_file)

    assert_includes css, "--primary: hsl(240 5.9% 10%);"
    assert_includes css, "--radius: 0.5rem;"
    assert_includes css, "--sidebar-ring:"
    assert(result[:filled].any? { |f| f.include?("--card (kept current value)") })
    assert_empty Shadcn::Theme.check[:errors]
  end

  test "import refuses input without theme blocks and leaves the file untouched" do
    before = File.read(Shadcn::Theme.theme_file)

    assert_raises(Shadcn::Theme::Error) { Shadcn::Theme.import("-", input: StringIO.new("body { color: red; }")) }
    assert_equal before, File.read(Shadcn::Theme.theme_file)
  end

  test "validate reports missing variables per mode" do
    palette = Shadcn::Theme::Palette.new(root: { "background" => "oklch(1 0 0)" }, dark: {})

    errors = Shadcn::Theme.validate(palette)[:errors]

    assert(errors.any? { |e| e.start_with?("light (:root): missing") && e.include?("primary") })
    assert(errors.any? { |e| e.start_with?("dark (.dark): missing") })
    assert_includes errors, "light (:root): missing --radius"
  end

  test "strict mode turns low contrast into an error" do
    palette = Shadcn::Theme.parse(File.read(File.join(@tmp, "presets", "zinc.css")))
    palette.root["muted-foreground"] = "oklch(0.9 0 0)"

    assert_empty Shadcn::Theme.validate(palette)[:errors]
    assert Shadcn::Theme.validate(palette, strict: true)[:errors].any? { |e| e.include?("muted-foreground") }
  end
end
