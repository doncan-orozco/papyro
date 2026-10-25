require "test_helper"
require "rake"

class ChadcnEngineTest < ActiveSupport::TestCase
  test "application.css imports the chadcn engine bundle" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_includes css, "/* chadcn:start"
    assert_includes css, "/* chadcn:end */"
    assert_includes css, '@import "../builds/tailwind/chadcn";'
    assert_includes css, '@import "./domains/articles/reader.css";'
  end

  test "application.css no longer carries duplicated vendor or token imports" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    assert_not_includes css, "./vendor/"
    assert_not_includes css, "./theme/tokens.css"
  end

  # The gem's importmap provides the pins its controllers import (@floating-ui/dom, primitives).
  test "importmap resolves the engine pins" do
    imports = JSON.parse(Rails.application.importmap.to_json(resolver: ActionController::Base.helpers))["imports"]

    assert imports.key?("@floating-ui/dom")
    assert imports.key?("controllers/chadcn/dialog_controller")
    assert imports.key?("chadcn/primitives/portal")
  end

  test "the engine vendored floating-ui is served by the asset pipeline" do
    assert_not_nil Rails.application.assets.load_path.find("@floating-ui--dom.js")
  end

  test "the engine javascript directory is on the asset paths exactly once" do
    gem_js = Chadcn.root.join("app/javascript").to_s
    paths = Rails.application.config.assets.paths.map(&:to_s)

    assert_equal 1, paths.count(gem_js)
  end

  test "the theme directory is the app's app/assets/tailwind/theme" do
    assert_equal Rails.root.join("app/assets/tailwind/theme").to_s, Chadcn::Theme.dir.to_s
  end

  test "the app theme is valid and ships the zinc and slate presets" do
    result = Chadcn::Theme.check

    assert_empty result[:errors]
    assert_includes Chadcn::Theme.presets, "zinc"
    assert_includes Chadcn::Theme.presets, "slate"
  end

  test "theme tasks come from the gem only" do
    gem_tasks = Chadcn.root.join("lib/tasks").to_s
    previous = [ Rake.application, Rake::TaskManager.record_task_metadata ]
    Rake::TaskManager.record_task_metadata = true
    Rake.application = Rake::Application.new
    Rails.application.load_tasks

    %w[list use import check].each do |name|
      [ "theme:#{name}", "chadcn:theme:#{name}" ].each do |task_name|
        task = Rake::Task[task_name]

        assert_not_empty task.locations, "#{task_name} has no recorded location"
        assert(task.locations.all? { |location| location.start_with?(gem_tasks) }, "#{task_name} defined outside the gem: #{task.locations}")
      end
    end
  ensure
    Rake.application, Rake::TaskManager.record_task_metadata = previous
  end

  # The host only consumes the gem's public API (Chadcn.root, the engine's pins, assets and tasks).
  test "host Ruby does not reach into the gem's internals or repo paths" do
    internals = /Chadcn::(?:Engine|Loader|Generators)\b|Chadcn::[\w:]+\.send\(|gems\/chadcn\/|ShadcnParity|Chadcn\.root[^\n]*\bdev\//
    files = Dir[Rails.root.join("{app,lib,config,test}/**/*.{rb,rake}")].map { |file| File.expand_path(file) } - [ File.expand_path(__FILE__) ]
    offenders = files.select { |file| File.read(file).match?(internals) }

    assert_empty offenders, "host files reaching into chadcn internals: #{offenders.join(', ')}"
  end
end
