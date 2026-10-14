# frozen_string_literal: true

require_relative "../engine/engine_helper"
require "rails/generators/test_case"
require "generators/phlex/shadcn/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Phlex::Shadcn::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator-destination", __dir__)

  TAILWIND_ENTRY = <<~CSS
    @import url("https://fonts.googleapis.com/css2?family=Manrope&display=swap");
    @import "tailwindcss";

    @import "./components/other.css";
  CSS

  setup do
    prepare_destination
    write("app/assets/tailwind/application.css", TAILWIND_ENTRY)
  end

  def css = File.read(File.join(destination_root, "app/assets/tailwind/application.css"))

  def write(path, content)
    full = File.join(destination_root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  def snapshot
    Dir.glob("**/*", base: destination_root).select { |path| File.file?(File.join(destination_root, path)) }.sort.to_h do |path|
      [ path, File.read(File.join(destination_root, path)) ]
    end
  end

  test "writes one block after the tailwind import with the source line, the engine bundle and the theme" do
    run_generator

    source = Pathname.new(Phlex::Shadcn.root.join("lib")).relative_path_from(Pathname.new(destination_root).join("app/assets/tailwind"))
    lines = css.lines.map(&:chomp)
    start = lines.index { |line| line.start_with?("/* phlex-shadcn:start") }

    assert_equal %(@import "tailwindcss";), lines[start - 1]
    assert_equal [ %(@source "#{source}";), %(@import "../builds/tailwind/phlex-shadcn";), %(@import "./theme/theme.css";), "/* phlex-shadcn:end */" ],
                 lines[(start + 1)..(start + 4)]
    assert_includes css, %(@import "./components/other.css";), "the rest of the file is untouched"
    assert_equal 1, css.scan("phlex-shadcn:start").size
  end

  test "the source line points at the directory that holds the gem's Ruby files" do
    run_generator
    path = css[/@source "([^"]+)"/, 1]
    resolved = Pathname.new(destination_root).join("app/assets/tailwind").join(path).cleanpath

    assert_equal Phlex::Shadcn.root.join("lib").cleanpath.to_s, resolved.to_s
    assert_predicate resolved.join("phlex/shadcn/button.rb"), :file?
  end

  test "copies the default theme and presets into the host" do
    run_generator

    assert_file "app/assets/tailwind/theme/theme.css", /theme:colors:start/
    assert_file "app/assets/tailwind/theme/presets/slate.css"
    assert_equal %w[gray neutral slate stone zinc zinc-radius0], Dir.children(File.join(destination_root, "app/assets/tailwind/theme/presets")).map { |f| File.basename(f, ".css") }.sort
    assert_no_file "app/assets/tailwind/theme/tokens.css"
  end

  test "is idempotent: a second run changes nothing" do
    run_generator
    first = snapshot
    output = run_generator

    assert_equal first, snapshot
    assert_match(%r{identical\s+app/assets/tailwind/application.css}, output)
  end

  test "keeps the theme the developer edited" do
    run_generator
    write("app/assets/tailwind/theme/theme.css", "/* my own colors */\n")
    run_generator

    assert_file "app/assets/tailwind/theme/theme.css", /my own colors/
  end

  test "updates the block when the gem moves but leaves the rest alone" do
    run_generator
    moved = css.sub(/@source "[^"]+";/, '@source "../../../old/gem/lib";')
    write("app/assets/tailwind/application.css", moved)
    run_generator

    refute_includes css, "old/gem"
    assert_equal 1, css.scan("phlex-shadcn:start").size
    assert_includes css, %(@import "./components/other.css";)
  end

  test "honours --css and --theme-dir" do
    write("app/assets/stylesheets/tw.css", %(@import "tailwindcss";\n))
    run_generator %w[--css app/assets/stylesheets/tw.css --theme-dir config/theme]
    entry = File.read(File.join(destination_root, "app/assets/stylesheets/tw.css"))

    assert_includes entry, %(@import "../builds/tailwind/phlex-shadcn";)
    assert_includes entry, %(@import "../../../config/theme/theme.css";)
    assert_file "config/theme/theme.css"
  end

  test "fails with a clear message when the tailwind entry file is missing" do
    FileUtils.rm(File.join(destination_root, "app/assets/tailwind/application.css"))
    output = capture(:stderr) { run_generator }

    assert_match(%r{not found: install tailwindcss-rails first \(bin/rails tailwindcss:install\)}, output)
    assert_no_file "app/assets/tailwind/theme/theme.css"
  end

  test "fails with a clear message when the entry file does not import tailwind" do
    write("app/assets/tailwind/application.css", "body { color: red; }\n")
    output = capture(:stderr) { run_generator }

    assert_match(/does not contain @import "tailwindcss"/, output)
    assert_equal "body { color: red; }\n", css, "the file is left untouched"
  end
end
