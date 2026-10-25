require "test_helper"
require "open3"
require "tmpdir"

# bin/pre-review runs the gem CI's local equivalents; these tests cover the wrapper (arguments, step selection, exit codes), not the gem.
# Where steps must really run, fake bundle/gem/ruby/rbenv executables come first on PATH.
class PreReviewTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("bin/pre-review").to_s

  setup { @gem_dir = Dir.mktmpdir("pre-review-gem") }
  teardown { FileUtils.remove_entry(@gem_dir) }

  def pre_review(*args, gem_dir: @gem_dir, env: {})
    out, err, status = Open3.capture3({ "BUNDLE_GEMFILE" => nil }.merge(env), SCRIPT, "--gem-dir", gem_dir, *args)
    [ out, err, status.exitstatus ]
  end

  def fake_bin(dir, name, body)
    path = File.join(dir, name)
    File.write(path, "#!/bin/sh\n#{body}\n")
    File.chmod(0o755, path)
  end

  def with_fakes(rbenv: "exit 0")
    Dir.mktmpdir("pre-review-bin") do |bin|
      fake_bin(bin, "bundle", 'echo "100.00% documented"')
      fake_bin(bin, "gem", "echo built")
      fake_bin(bin, "ruby", "exit 0")
      fake_bin(bin, "rbenv", rbenv)
      yield({ "PATH" => "#{bin}:/usr/bin:/bin" })
    end
  end

  test "dry run lists every step of the gem CI without running any" do
    out, _, code = pre_review("--dry-run")

    assert_equal 0, code
    %w[yard build gate smoke docs].each { |name| assert_match(/would  #{name} /, out) }
    assert_match(/would  rubies - plain smoke on ruby 3\.3/, out)
    assert_match(/would  rubies - plain smoke on ruby 3\.4/, out)
  end

  test "skip drops the named steps and rubies picks the versions" do
    out, _, code = pre_review("--dry-run", "--skip", "yard,docs", "--rubies", "3.5")

    assert_equal 0, code
    assert_match(/skip   yard/, out)
    assert_match(/skip   docs/, out)
    assert_match(/would  build /, out)
    assert_match(/ruby 3\.5/, out)
    assert_no_match(/ruby 3\.3/, out)
  end

  test "a failing step makes the run red" do
    _, err, code = pre_review("--skip", "build,gate,smoke,docs,rubies") # the empty directory has no Gemfile, so yard cannot pass

    assert_equal 1, code
    assert_match(/FAILED yard/, err)
    assert_match(/RED/, err)
  end

  test "every step green exits 0" do
    with_fakes do |env|
      out, _, code = pre_review("--skip", "rubies", env: env)

      assert_equal 0, code
      assert_match(/ok     yard/, out)
      assert_match(/ok     build/, out)
      assert_match(/GREEN/, out)
    end
  end

  test "a ruby that is not installed is reported as NOT RUN and the run is not green" do
    with_fakes(rbenv: 'echo "4.0.1"') do |env|
      _, err, code = pre_review("--skip", "yard,build,gate,smoke,docs", "--rubies", "3.3", env: env)

      assert_equal 3, code
      assert_match(/NOT RUN ruby 3\.3/, err)
      assert_match(/GREEN except NOT RUN rubies: 3\.3/, err)
    end
  end

  test "a missing gem directory is an error" do
    _, err, code = pre_review("--dry-run", gem_dir: File.join(@gem_dir, "nope"))

    assert_equal 2, code
    assert_match(/not found/, err)
  end

  test "an unknown option is an error" do
    _, err, code = pre_review("--bogus")

    assert_equal 2, code
    assert_match(/unknown option/, err)
  end

  test "the default gem directory is the chadcn sibling of the main checkout" do
    Dir.mktmpdir("pre-review-main") do |root|
      repo = File.join(root, "papyro")
      FileUtils.mkdir_p([ File.join(repo, "bin"), File.join(root, "chadcn") ])
      FileUtils.cp(SCRIPT, File.join(repo, "bin/pre-review"))
      system("git", "-C", repo, "init", "-q", exception: true)
      out, err, status = Open3.capture3({ "BUNDLE_GEMFILE" => nil, "PRE_REVIEW_GEM_DIR" => nil }, "bin/pre-review", "--dry-run", chdir: repo)

      assert_equal 0, status.exitstatus, err
      assert_match(/would  yard/, out)
    end
  end
end
