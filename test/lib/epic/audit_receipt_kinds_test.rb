require "test_helper"
require "tmpdir"
require Rails.root.join(".claude/scripts/audit_receipt").to_s

# Per-kind dimension labels (docs, tooling, gem) on top of the canonical five-key receipt.
class AuditReceiptKindsTest < ActiveSupport::TestCase
  DOCS = { "structure" => 9, "clarity" => 8, "maintainability" => 8, "accuracy" => 9, "verifiability" => 8 }.freeze
  CANONICAL = { "architecture" => 9, "clean_code" => 8, "scalability" => 8, "security" => 9, "testability" => 8 }.freeze

  setup do
    @dir = Dir.mktmpdir("audit-receipt-kinds")
    @repo = File.join(@dir, "repo")
    system("git", "init", "-q", @repo, exception: true)
    File.write(File.join(@repo, "a.md"), "# doc\n")
    @receipt = File.join(@dir, "scorecard.json")
  end

  teardown { FileUtils.remove_entry(@dir) }

  def write(scores, kind:) = AuditReceipt.write(@receipt, scores: scores, verdict: "PASS", mandatory_open: 0, iterations: 1, dir: @repo, kind: kind)

  test "a docs receipt takes docs labels and stores the canonical keys" do
    receipt = write(DOCS, kind: "docs")

    assert_equal CANONICAL, receipt["scores"]
    assert_equal "docs", receipt["kind"]
    assert AuditReceipt.check(@receipt, dir: @repo)["ok"]
  end

  test "a docs receipt names the weak dimension by its docs label" do
    write(DOCS.merge("accuracy" => 6), kind: "docs")

    assert_equal [ "accuracy=6 is below 8" ], AuditReceipt.check(@receipt, dir: @repo)["reasons"]
  end

  test "canonical keys are accepted for every kind" do
    assert_equal CANONICAL, write(CANONICAL, kind: "tooling")["scores"]
  end

  test "the default kind writes the same receipt as before, without a kind key" do
    receipt = write(CANONICAL, kind: "code")

    refute receipt.key?("kind")
    assert AuditReceipt.check(@receipt, dir: @repo)["ok"]
  end

  test "an unknown kind is refused on write and on check" do
    assert_raises(AuditReceipt::Error) { write(CANONICAL, kind: "poetry") }

    write(CANONICAL, kind: "docs")
    data = JSON.parse(File.read(@receipt)).merge("kind" => "poetry")
    File.write(@receipt, JSON.generate(data))

    refute AuditReceipt.check(@receipt, dir: @repo)["ok"]
  end

  test "a label of another kind is rejected as unknown" do
    assert_raises(AuditReceipt::Error) { write(DOCS, kind: "tooling") }
  end
end
