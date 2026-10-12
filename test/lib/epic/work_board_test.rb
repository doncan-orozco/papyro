require "test_helper"
require "tmpdir"
require "open3"
require "rbconfig"
require "stringio"
require Rails.root.join("test/supports/fake_gh").to_s
require Rails.root.join(".claude/scripts/epic/work_board").to_s

# In-process runs route `gh` to FakeGh (fast); the concurrency test runs the real script as subprocesses instead.
module FakeGhRoute
  def gh(*args)
    FakeGh.call(args)
  rescue FakeGh::Error => e
    raise WorkBoard::Failure, e.message
  end
end
WorkBoard::Shell.prepend(FakeGhRoute)

# Golden tests for the multi-session coordination board (.claude/scripts/epic/work_board.rb). GitHub is replaced by
# test/supports/fake_gh.rb; claims are real git refs on a local bare repository, so the atomicity under test is git's own.
class WorkBoardTest < ActiveSupport::TestCase
  SCRIPT = Rails.root.join(".claude/scripts/epic/work_board.rb").to_s
  FAKE_GH = Rails.root.join("test/supports/fake_gh.rb").to_s
  T0 = "2026-10-12T10:00:00Z"

  setup do
    @dir = Dir.mktmpdir("work-board")
    @remote = File.join(@dir, "remote.git")
    @work = File.join(@dir, "work")
    system("git", "init", "-q", "--bare", @remote, exception: true)
    system("git", "init", "-q", @work, exception: true)
    system("git", "-C", @work, "remote", "add", "origin", @remote, exception: true)
    @db = File.join(@dir, "gh.json")
  end

  teardown { FileUtils.remove_entry(@dir) }

  # Runs a command in-process like an agent's CLI call would; returns [parsed JSON (or {"raw"=>text}), exit status].
  def wb(*args, now: T0, env: {})
    saved = ENV.to_h.slice("WORK_NOW", "WORK_FAKE_DB", "WORK_REMOTE", "WORK_SESSION")
    ENV.update({ "WORK_FAKE_DB" => @db, "WORK_REMOTE" => "origin", "WORK_NOW" => now }.merge(env))
    ENV.delete("WORK_SESSION") unless env.key?("WORK_SESSION")
    out = StringIO.new
    code = 0
    real_out, real_err = $stdout, $stderr
    $stdout, $stderr = out, StringIO.new
    Dir.chdir(@work) do
      WorkBoard::Cli.new(args).run
    rescue SystemExit => e
      code = e.status
    end
    [ (JSON.parse(out.string) rescue { "raw" => out.string }), code ]
  ensure
    $stdout, $stderr = real_out, real_err
    %w[WORK_NOW WORK_FAKE_DB WORK_REMOTE WORK_SESSION].each { |k| saved[k] ? ENV[k] = saved[k] : ENV.delete(k) }
  end

  # Same call as a real subprocess (real `ruby script`, real fake_gh executable): used where true parallelism matters.
  def wb_process(*args, now: T0)
    out, _err, status = Open3.capture3({ "WORK_GH" => "#{RbConfig.ruby} #{FAKE_GH}", "WORK_FAKE_DB" => @db, "WORK_REMOTE" => "origin", "WORK_NOW" => now },
                                       RbConfig.ruby, SCRIPT, *args, chdir: @work)
    [ (JSON.parse(out) rescue { "raw" => out }), status.exitstatus ]
  end

  def make_epic(slug = "demo")
    wb("epic", "create", "--slug", slug, "--title", "Demo epic", "--body", "plan")[0]["number"]
  end

  def make_item(title, wave:, owns:, blocked_by: [], stage: "plan", slug: "demo")
    args = [ "item", "create", "--epic", slug, "--title", title, "--body", "do #{title}", "--wave", wave.to_s, "--owns", owns, "--stage", stage ]
    args += [ "--blocked-by", blocked_by.join(",") ] if blocked_by.any?
    wb(*args)[0]["number"]
  end

  def claim(number, session, slug: "demo", now: T0, lease: nil)
    args = [ "claim", number.to_s, "--epic", slug, "--session", session ]
    args += [ "--lease", lease.to_s ] if lease
    wb(*args, now: now)
  end

  def state_of(number, slug: "demo") = wb("status", "--epic", slug)[0]["items"].find { |i| i["number"] == number }
  def fake_db = File.exist?(@db) ? JSON.parse(File.read(@db)) : { "issues" => [] }

  # ---- plan creation and validation ----------------------------------------------------------------------------
  test "epic and items are created with labels, stage and a machine-readable meta block" do
    root = make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    issue = fake_db["issues"].find { |i| i["number"] == a }

    assert_equal 1, root
    assert_includes issue["labels"].map { |l| l["name"] }, "epic:demo"
    assert_includes issue["labels"].map { |l| l["name"] }, "stage:plan"
    assert_includes issue["labels"].map { |l| l["name"] }, "wave:1"
    assert_match(/work-item \{.*"owns":\["lib\/a\/\*\*"\]/, issue["body"])
    assert_includes fake_db["issues"].first["labels"].map { |l| l["name"] }, "epic-root"
  end

  test "validate passes a clean plan and reports every kind of plan defect" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    make_item("B", wave: 2, owns: "lib/b/**", blocked_by: [ a ])
    result, code = wb("validate", "--epic", "demo")

    assert_equal 0, code, result.inspect
    assert result["pass"]

    c = make_item("C", wave: 1, owns: "lib/a/x.rb")             # parallel to A, overlapping files
    d = make_item("D", wave: 1, owns: "lib/d/**", blocked_by: [ a ]) # same wave as its blocker
    e = make_item("E", wave: 3, owns: "lib/e/**", blocked_by: [ 999 ]) # blocker outside the epic
    result, code = wb("validate", "--epic", "demo")
    codes = result["findings"].map { |f| [ f["code"], f["item"] ] }

    assert_equal 1, code
    assert_includes codes, [ "OWNS_OVERLAP", a ]
    assert_includes codes, [ "WAVE_ORDER", d ]
    assert_includes codes, [ "BLOCKER_MISSING", e ]
    overlap = result["findings"].find { |f| f["code"] == "OWNS_OVERLAP" }["detail"]

    assert_match(/\A#{a} and #{c} can run in parallel/, overlap)
  end

  test "validate detects dependency cycles" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    b = make_item("B", wave: 2, owns: "lib/b/**", blocked_by: [ a ])
    db = fake_db
    db["issues"].find { |i| i["number"] == a }["body"].sub!('"blocked_by":[]', %("blocked_by":[#{b}]))
    File.write(@db, JSON.generate(db))
    result, code = wb("validate", "--epic", "demo")

    assert_equal 1, code
    assert(result["findings"].any? { |f| f["code"] == "CYCLE" })
  end

  test "validate requires owns on every item" do
    make_epic
    db_args = [ "item", "create", "--epic", "demo", "--title", "no owns", "--wave", "1", "--owns", "x" ]
    wb(*db_args)
    db = fake_db
    db["issues"].last["body"].sub!('"owns":["x"]', '"owns":[]')
    File.write(@db, JSON.generate(db))

    assert(wb("validate", "--epic", "demo")[0]["findings"].any? { |f| f["code"] == "OWNS_MISSING" })
  end

  # ---- picking work ------------------------------------------------------------------------------------------------
  test "next returns the lowest wave ready item and never an item with an open blocker" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    b = make_item("B", wave: 2, owns: "lib/b/**", blocked_by: [ a ])
    c = make_item("C", wave: 1, owns: "lib/c/**")

    assert_equal a, wb("next", "--epic", "demo")[0]["item"]["number"]
    claim(a, "s1")

    assert_equal c, wb("next", "--epic", "demo")[0]["item"]["number"], "B stays hidden while A is open"
    claim(c, "s2")
    result = wb("next", "--epic", "demo")[0]

    assert_nil result["item"]
    assert_equal "claimed_by_others", result["reason"]
  end

  test "an item becomes ready only when every blocker is done" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    b = make_item("B", wave: 2, owns: "lib/b/**", blocked_by: [ a ])
    claim(a, "s1")
    wb("advance", a.to_s, "--epic", "demo", "--session", "s1", "--stage", "done")

    assert_equal "ready", state_of(b)["state"]
    assert_equal "done", state_of(a)["state"]
    assert_equal "CLOSED", fake_db["issues"].find { |i| i["number"] == a }["state"]
  end

  test "next skips an item whose files overlap an item another session is working on" do
    make_epic
    a = make_item("A", wave: 1, owns: "app/shared/**")
    b = make_item("B", wave: 1, owns: "app/shared/tweak.rb") # also overlap-flagged by validate; here we test the runtime guard
    claim(a, "s1")
    result, = wb("next", "--epic", "demo")
    refused, code = claim(b, "s2")

    assert_nil result["item"]
    assert_equal "filtered", result["reason"]
    assert_equal 1, code
    assert_equal "owns_overlap", refused["reason"]
    assert_equal [ a ], refused["with"]
  end

  test "next with --stage only offers items in those stages" do
    make_epic
    make_item("A", wave: 1, owns: "lib/a/**", stage: "plan")
    audit = make_item("B", wave: 1, owns: "lib/b/**", stage: "audit")

    assert_equal audit, wb("next", "--epic", "demo", "--stage", "audit")[0]["item"]["number"]
    assert_equal "filtered", wb("next", "--epic", "demo", "--stage", "review")[0]["reason"]
  end

  test "the session that built an item is never offered its audit" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**", stage: "build")
    claim(a, "builder")
    wb("advance", a.to_s, "--epic", "demo", "--session", "builder", "--stage", "audit", "--note", "built")

    assert_nil wb("next", "--epic", "demo", "--stage", "audit", "--session", "builder")[0]["item"]
    assert_equal a, wb("next", "--epic", "demo", "--stage", "audit", "--session", "reviewer")[0]["item"]["number"]
  end

  # ---- claims --------------------------------------------------------------------------------------------------------
  test "a held item cannot be claimed by another session, the holder can resume" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    first, code = claim(a, "s1")

    assert_equal 0, code
    assert first["claimed"]
    assert_includes fake_db["issues"].find { |i| i["number"] == a }["labels"].map { |l| l["name"] }, "claimed"

    second, code = claim(a, "s2")

    assert_equal 1, code
    assert_equal "held", second["reason"]
    assert_equal "s1", second["holder"]

    again, code = claim(a, "s1")

    assert_equal 0, code
    assert again["resumed"]
  end

  test "exactly one of many concurrent sessions wins an item" do
    make_epic
    3.times do |round|
      number = make_item("race-#{round}", wave: 1, owns: "lib/race#{round}/**")
      results = 8.times.map do |i|
        Thread.new { wb_process("claim", number.to_s, "--epic", "demo", "--session", "racer-#{i}") }
      end.map(&:value)
      winners = results.select { |_, code| code.zero? }

      assert_equal 1, winners.size, "round #{round}: #{results.map { |r, c| [ c, r['reason'] ] }.inspect}"
      holder = state_of(number)["holder"]

      assert_equal winners.first[0]["session"], holder
    end
  end

  test "a claim whose lease expired is taken over and the old holder is told it lost the item" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1", lease: 1)
    later = "2026-10-12T10:05:00Z"

    assert_equal "ready", wb("status", "--epic", "demo", now: later)[0]["items"].first["state"], "an expired claim no longer blocks"
    assert_equal a, wb("next", "--epic", "demo", now: later)[0]["item"]["number"]

    taken, code = claim(a, "s2", now: later)

    assert_equal 0, code, taken.inspect
    stale, code = wb("heartbeat", a.to_s, "--epic", "demo", "--session", "s1", now: later)

    assert_equal 1, code
    assert_equal "held_by_other", stale["reason"]
    _, code = wb("release", a.to_s, "--epic", "demo", "--session", "s1", now: later)

    assert_equal 1, code
    assert_equal "s2", wb("status", "--epic", "demo", now: later)[0]["items"].first["holder"]
  end

  test "heartbeat extends the lease so the item is not taken over" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1", lease: 10)
    _, code = wb("heartbeat", a.to_s, "--epic", "demo", "--session", "s1", "--lease", "10", now: "2026-10-12T10:08:00Z")

    assert_equal 0, code
    at_twelve = wb("status", "--epic", "demo", now: "2026-10-12T10:12:00Z")[0]["items"].first

    assert_equal "in-progress", at_twelve["state"], "lease was renewed at 10:08 for 10 minutes"
    assert_equal "s1", at_twelve["holder"]
  end

  test "reap frees expired claims and clears their label" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1", lease: 1)
    result, = wb("reap", "--epic", "demo", now: "2026-10-12T11:00:00Z")

    assert_equal [ { "number" => a, "was_held_by" => "s1" } ], result["freed"]
    refute_includes fake_db["issues"].find { |i| i["number"] == a }["labels"].map { |l| l["name"] }, "claimed"
    assert_empty wb("reap", "--epic", "demo", now: "2026-10-12T11:00:00Z")[0]["freed"]
  end

  test "only the holder can release and release makes the item claimable again" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1")
    _, code = wb("release", a.to_s, "--epic", "demo", "--session", "s2")

    assert_equal 1, code
    _, code = wb("release", a.to_s, "--epic", "demo", "--session", "s1")

    assert_equal 0, code
    assert_equal 0, claim(a, "s2")[1]
  end

  test "claim refuses an item that is not ready" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    b = make_item("B", wave: 2, owns: "lib/b/**", blocked_by: [ a ])
    result, code = claim(b, "s1")

    assert_equal 1, code
    assert_equal "not_ready", result["reason"]
  end

  test "an unreachable remote is an error, never an empty claim list" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    _, code = wb("claim", a.to_s, "--epic", "demo", "--session", "s1", env: { "WORK_REMOTE" => File.join(@dir, "missing.git") })

    assert_equal 2, code
  end

  # ---- stages, blocking, notes ---------------------------------------------------------------------------------
  test "advance moves the stage label, logs the transition and releases; --keep holds the claim" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1")
    kept, code = wb("advance", a.to_s, "--epic", "demo", "--session", "s1", "--stage", "test-plan", "--keep")

    assert_equal 0, code, kept.inspect
    assert_equal "s1", wb("status", "--epic", "demo")[0]["items"].first["holder"]
    wb("advance", a.to_s, "--epic", "demo", "--session", "s1", "--stage", "build")
    labels = fake_db["issues"].find { |i| i["number"] == a }["labels"].map { |l| l["name"] }

    assert_includes labels, "stage:build"
    refute_includes labels, "stage:plan"
    refute_includes labels, "claimed"
    assert_nil wb("status", "--epic", "demo")[0]["items"].first["holder"]
    logs = fake_db["issues"].find { |i| i["number"] == a }["comments"].map { |c| c["body"] }

    assert_equal 2, logs.count { |b| b.include?('"type":"stage-log"') }
  end

  test "advance and block are refused for a session that does not hold the item" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1")

    assert_equal 1, wb("advance", a.to_s, "--epic", "demo", "--session", "s2", "--stage", "build")[1]
    assert_equal 1, wb("block", a.to_s, "--epic", "demo", "--session", "s2", "--reason", "nope")[1]
    assert_equal 2, wb("advance", a.to_s, "--epic", "demo", "--session", "s1", "--stage", "nonsense")[1]
  end

  test "block releases the claim, labels needs-human and leaves a blocker note; unblock restores readiness" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1")
    wb("block", a.to_s, "--epic", "demo", "--session", "s1", "--reason", "gate keeps failing on X")

    assert_equal "blocked", state_of(a)["state"]
    assert_equal "needs_human", wb("next", "--epic", "demo")[0]["reason"]
    assert_equal 1, claim(a, "s2")[1]
    wb("unblock", a.to_s, "--epic", "demo")

    assert_equal "ready", state_of(a)["state"]
    assert_match(/gate keeps failing on X/, wb("digest", "--epic", "demo", "--item", a.to_s)[0]["notes"].first["body"])
  end

  test "digest gives a worker the epic thread, its own notes and its blockers' shared notes, and nothing else" do
    root = make_epic
    base = make_item("Base class", wave: 1, owns: "lib/base/**")
    other = make_item("Unrelated", wave: 1, owns: "lib/other/**")
    user = make_item("Consumer", wave: 2, owns: "lib/user/**", blocked_by: [ base ])
    wb("comment", root.to_s, "--epic", "demo", "--session", "lead", "--type", "announce", "--body", "rebase on main after #{base}")
    wb("comment", root.to_s, "--epic", "demo", "--session", "s1", "--type", "lesson", "--body", "Slot classes join plainly")
    wb("comment", base.to_s, "--epic", "demo", "--session", "s1", "--type", "shared", "--body", "Base lives in lib/base/base.rb; use cn(...)")
    wb("comment", other.to_s, "--epic", "demo", "--session", "s3", "--type", "shared", "--body", "secret of the unrelated item")
    wb("comment", user.to_s, "--epic", "demo", "--session", "s2", "--type", "handoff", "--body", "left off at the table spec")
    bodies = wb("digest", "--epic", "demo", "--item", user.to_s)[0]["notes"].map { |n| n["body"] }.join("\n")

    assert_includes bodies, "rebase on main"
    assert_includes bodies, "Slot classes join plainly"
    assert_includes bodies, "Base lives in lib/base/base.rb"
    assert_includes bodies, "left off at the table spec"
    refute_includes bodies, "secret of the unrelated item"

    md = wb("digest", "--epic", "demo", "--item", user.to_s, "--format", "md")[0]["raw"]

    assert_match(/### \[shared\] ##{base} by s1/, md)
  end

  test "comments reject unknown types and empty bodies" do
    root = make_epic

    assert_equal 2, wb("comment", root.to_s, "--epic", "demo", "--session", "s1", "--type", "gossip", "--body", "x")[1]
    assert_equal 2, wb("comment", root.to_s, "--epic", "demo", "--session", "s1", "--type", "shared", "--body", "  ")[1]
  end

  test "status counts items by state" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    make_item("B", wave: 1, owns: "lib/b/**")
    make_item("C", wave: 2, owns: "lib/c/**", blocked_by: [ a ])
    claim(a, "s1")

    assert_equal({ "in-progress" => 1, "ready" => 1, "waiting" => 1 }, wb("status", "--epic", "demo")[0]["counts"])
  end

  test "session id is stable per checkout and WORK_SESSION overrides it" do
    first = wb("session")[0]["session"]

    assert_equal first, wb("session")[0]["session"]
    assert_equal "from-env", wb("session", env: { "WORK_SESSION" => "from-env" })[0]["session"]
  end

  test "the real script and the real gh-shaped executable work end to end as subprocesses" do
    root, code = wb_process("epic", "create", "--slug", "demo", "--title", "Demo", "--body", "plan")

    assert_equal 0, code, root.inspect
    item, = wb_process("item", "create", "--epic", "demo", "--title", "A", "--wave", "1", "--owns", "lib/a/**", "--body", "x")

    assert_equal 0, wb_process("claim", item["number"].to_s, "--epic", "demo", "--session", "s1")[1]
    assert_equal 1, wb_process("claim", item["number"].to_s, "--epic", "demo", "--session", "s2")[1]
  end

  # ---- plan files ---------------------------------------------------------------------------------------------------
  def plan_file(items: nil, epic: { "slug" => "gemx", "title" => "Gem epic", "body" => "scope" })
    items ||= [
      { "key" => "skeleton", "title" => "Gem skeleton", "wave" => 0, "owns" => [ "gems/x/**" ], "goal" => "make it", "gates" => [ "bundle exec rake test" ], "acceptance" => [ "suite green" ] },
      { "key" => "move", "title" => "Move code", "wave" => 1, "owns" => [ "gems/x/lib/**" ], "blocked_by" => [ "skeleton" ], "goal" => "move", "gates" => [ "ruby check.rb" ], "acceptance" => [ "all pass" ], "context" => "see skeleton" },
      { "key" => "docs", "title" => "Docs", "wave" => 1, "owns" => [ "gems/x/README.md" ], "blocked_by" => [ "skeleton" ], "goal" => "write", "gates" => [ "true" ], "acceptance" => [ "readme" ] }
    ]
    path = File.join(@dir, "plan.json")
    File.write(path, JSON.generate("epic" => epic, "items" => items))
    path
  end

  test "plan-check accepts a complete plan" do
    result, code = wb("plan-check", "--file", plan_file)

    assert_equal 0, code, result.inspect
    assert result["pass"]
  end

  test "plan-check rejects items without goal, gates or acceptance and plans with structural defects" do
    items = [
      { "key" => "a", "title" => "A", "wave" => 1, "owns" => [ "lib/a/**" ], "goal" => "g", "gates" => [], "acceptance" => [ "x" ] },
      { "key" => "b", "title" => "B", "wave" => 1, "owns" => [ "lib/a/x.rb" ], "goal" => "g", "gates" => [ "true" ], "acceptance" => [ "x" ] },
      { "key" => "b", "title" => "B2", "wave" => 2, "owns" => [ "lib/z/**" ], "blocked_by" => [ "ghost" ], "goal" => "g", "gates" => [ "true" ], "acceptance" => [ "x" ] }
    ]
    result, code = wb("plan-check", "--file", plan_file(items: items))
    codes = result["findings"].map { |f| f["code"] }

    assert_equal 1, code
    assert_includes codes, "FIELD_MISSING"
    assert_includes codes, "OWNS_OVERLAP"
    assert_includes codes, "DUPLICATE_ID"
    assert_includes codes, "BLOCKER_MISSING"
    assert_equal 1, wb("plan-check", "--file", plan_file(epic: { "slug" => "Bad Slug", "title" => "" }))[1]
  end

  test "plan-apply creates the root and every item in dependency order with resolved blockers and a contract body" do
    result, code = wb("plan-apply", "--file", plan_file)
    numbers = result["items"]

    assert_equal 0, code, result.inspect
    assert_operator numbers["skeleton"], :<, numbers["move"]
    move = fake_db["issues"].find { |i| i["number"] == numbers["move"] }

    assert_includes move["body"], "## Gates"
    assert_includes move["body"], "`ruby check.rb`"
    assert_includes move["body"], "- ##{numbers['skeleton']} (skeleton)"
    assert_includes move["body"], "see skeleton"
    assert_match(/"blocked_by":\[#{numbers['skeleton']}\]/, move["body"])
    assert wb("validate", "--epic", "gemx")[0]["pass"]
    assert_equal numbers["skeleton"], wb("next", "--epic", "gemx")[0]["item"]["number"]
  end

  test "plan-apply refuses an invalid plan and an epic that already exists" do
    bad = plan_file(items: [ { "key" => "a", "title" => "A", "wave" => 1, "owns" => [], "goal" => "g", "gates" => [ "true" ], "acceptance" => [ "x" ] } ])

    assert_equal 1, wb("plan-apply", "--file", bad)[1]
    assert_empty fake_db["issues"] || []
    assert_equal 0, wb("plan-apply", "--file", plan_file)[1]
    again, code = wb("plan-apply", "--file", plan_file)

    assert_equal 1, code
    assert_match(/already has issues/, again["error"])
    assert_equal 4, fake_db["issues"].size
  end

  test "show returns the item without the machine block, its notes and the current holder" do
    wb("plan-apply", "--file", plan_file)
    first = wb("next", "--epic", "gemx")[0]["item"]["number"]
    claim(first, "s1", slug: "gemx")
    wb("comment", first.to_s, "--epic", "gemx", "--session", "s1", "--type", "handoff", "--body", "started")
    shown = wb("show", first.to_s, "--epic", "gemx")[0]

    assert_equal "s1", shown["holder"]
    refute_includes shown["body"], "work-item"
    assert_includes shown["body"], "## Acceptance"
    assert_equal [ "handoff" ], shown["notes"].map { |n| n["type"] }
  end

  test "a human can force-release an abandoned claim of any session" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "gone-session")
    result, code = wb("release", a.to_s, "--epic", "demo", "--force")

    assert_equal 0, code
    assert_equal "gone-session", result["was_held_by"]
    assert_equal 0, claim(a, "s2")[1]
    assert_equal 1, wb("release", "999", "--epic", "demo", "--force")[1]
  end

  # ---- documentation stays honest ----------------------------------------------------------------------------------
  test "commands and skills only mention work_board subcommands that exist" do
    subcommands = File.read(SCRIPT)[/def run\n.*?\n    end\n/m].scan(/when "([\w-]+)"/).flatten
    docs = Dir[Rails.root.join(".claude/commands/{epic-plan,work,work-status,work-release}.md").to_s, Rails.root.join(".ai/skills/epic-flow/**/*.md").to_s]
    mentioned = docs.flat_map { |f| File.read(f).scan(/work_board\.rb\s+(?:epic |item )?([a-z][a-z-]*)/).flatten }.uniq

    assert_predicate docs, :any?, "expected the epic commands and skill to exist"
    assert_empty mentioned - subcommands - %w[create], "documented but not implemented: #{(mentioned - subcommands).inspect}"
  end

  test "rule numbers cited by the commands exist in the epic-flow skill" do
    skill = File.read(Rails.root.join(".ai/skills/epic-flow/SKILL.md"))
    defined_rules = skill.scan(/^R(\d+)\./).flatten.map(&:to_i)
    cited = Dir[Rails.root.join(".claude/commands/{epic-plan,work,work-status,work-release}.md").to_s].flat_map { |f| File.read(f).scan(/\bR(\d+)\b/).flatten.map(&:to_i) }.uniq

    assert_equal (1..defined_rules.max).to_a, defined_rules.sort, "rules are numbered without gaps"
    assert_empty cited - defined_rules, "commands cite rules the skill does not define"
  end

  test "an unknown epic is an error for workers, never all_done; validate reports it as a finding" do
    %w[status next reap].each do |cmd|
      result, code = wb(cmd, "--epic", "typo")

      assert_equal 2, code, cmd
      assert_match(/epic typo not found/, result["error"])
    end
    result, code = wb("validate", "--epic", "typo")

    assert_equal 1, code
    assert_equal "NO_ROOT", result["findings"].first["code"]
  end

  test "unblock works although the blocked label was never created (real gh rejects removing unknown labels)" do
    make_epic
    a = make_item("A", wave: 1, owns: "lib/a/**")
    claim(a, "s1")
    wb("block", a.to_s, "--epic", "demo", "--session", "s1", "--reason", "stuck")
    result, code = wb("unblock", a.to_s, "--epic", "demo")

    assert_equal 0, code, result.inspect
    assert_equal "ready", state_of(a)["state"]
    refute_includes fake_db["issues"].find { |i| i["number"] == a }["labels"].map { |l| l["name"] }, "needs-human"
  end
end
