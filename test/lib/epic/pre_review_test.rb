require "test_helper"
require "open3"
require "tmpdir"

# bin/pre-review runs the gem CI's local equivalents; these tests cover the wrapper (arguments, step selection, exit codes), not the gem.
class PreReviewTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join("bin/pre-review").to_s

  setup { @gem_dir = Dir.mktmpdir("pre-review-gem") }
  teardown { FileUtils.remove_entry(@gem_dir) }

  def pre_review(*args)
    out, err, status = Open3.capture3({ "BUNDLE_GEMFILE" => nil }, SCRIPT, "--gem-dir", @gem_dir, *args)
    [ out, err, status.exitstatus ]
  end

  test "dry run lists every step of the gem CI without running any" do
    out, _, code = pre_review("--dry-run")

    assert_equal 0, code
    %w[yard build smoke docs].each { |name| assert_match(/would  #{name} /, out) }
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
    _, err, code = pre_review("--skip", "build,smoke,docs,rubies") # the empty directory has no Gemfile, so yard cannot pass

    assert_equal 1, code
    assert_match(/FAILED yard/, err)
  end

  test "a missing gem directory or an unknown option is an error" do
    _, err, code = Open3.capture3(SCRIPT, "--gem-dir", File.join(@gem_dir, "nope"), "--dry-run").then { |o, e, s| [ o, e, s.exitstatus ] }

    assert_equal 2, code
    assert_match(/not found/, err)

    _, err, code = pre_review("--bogus")

    assert_equal 2, code
    assert_match(/unknown option/, err)
  end
end
