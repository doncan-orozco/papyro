# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"
require "rubygems/package"
require "tmpdir"
require "uri"

# Builds the gem and inspects the package itself (not the working tree): a consumer gets what the README links to, and no dev-kit material.
class PackagingTest < Minitest::Test
  GEM_DIR = File.expand_path("../..", __dir__)

  @built = nil

  def self.built
    @built ||= begin
      dir = Dir.mktmpdir("phlex-shadcn-package")
      Minitest.after_run { FileUtils.remove_entry(dir) }
      out, status = Open3.capture2e(RbConfig.ruby, "-S", "gem", "build", "phlex-shadcn.gemspec", "--output", File.join(dir, "phlex-shadcn.gem"), chdir: GEM_DIR)
      raise "gem build failed:\n#{out}" unless status.success?

      package = Gem::Package.new(File.join(dir, "phlex-shadcn.gem"))
      { warnings: out, spec: package.spec, files: package.spec.files }
    end
  end

  def built = self.class.built

  def test_gem_build_prints_no_warning
    refute_match(/warning/i, built[:warnings])
  end

  def test_every_docs_link_of_readme_and_changelog_is_in_the_package
    links = %w[README.md CHANGELOG.md].flat_map { |name| File.read(File.join(GEM_DIR, name)).scan(/\]\((?!https?:|#|mailto:)([^)#\s]+)/).flatten }
    targets = links.uniq.select { |target| target.start_with?("docs/") }

    refute_empty targets, "README.md links no docs/ page: the check proves nothing"
    # A link to the directory ("docs/") is satisfied by any packaged file below it.
    missing = targets.reject { |target| target.end_with?("/") ? built[:files].any? { |f| f.start_with?(target) } : built[:files].include?(target) }

    assert_empty missing, "linked from README.md/CHANGELOG.md but not packaged: #{missing.join(', ')}"
  end

  def test_yardopts_and_the_docs_listed_by_it_are_in_the_package
    assert_includes built[:files], ".yardopts"
    listed = File.read(File.join(GEM_DIR, ".yardopts")).scan(%r{docs/\S+\.md}).uniq

    assert_empty listed - built[:files]
  end

  def test_no_dev_only_controller_is_packaged
    leaked = built[:files].grep(%r{(?:\A|/)(?:_probe_[^/]*|theme_panel_controller\.js)\z})

    assert_empty leaked, "dev-only controllers every consumer would pin and register: #{leaked.join(', ')}"
  end

  def test_no_dev_kit_tests_or_dummy_app_is_packaged
    assert_empty built[:files].grep(%r{\A(?:dev|test|tmp)/}), "dev material packaged"
  end

  def test_the_probes_and_the_theme_panel_live_in_the_dummy_app
    controllers = File.join(GEM_DIR, "dev/dummy/app/javascript/controllers/shadcn")

    refute_empty Dir[File.join(controllers, "_probe_*_controller.js")]
    assert_path_exists File.join(controllers, "theme_panel_controller.js")
  end

  def test_metadata_uris_parse_and_have_the_github_shape
    metadata = built[:spec].metadata
    shape = %r{\Ahttps://github\.com/[\w.-]+/[\w.-]+/blob/[\w.-]+/gems/phlex-shadcn/CHANGELOG\.md\z}

    assert_match shape, metadata["changelog_uri"]
    [ built[:spec].homepage, metadata["source_code_uri"], metadata["changelog_uri"] ].each do |uri|
      assert_instance_of URI::HTTPS, URI.parse(uri), uri
    end
  end
end
