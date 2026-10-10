#!/usr/bin/env ruby
# frozen_string_literal: true

# Deterministic half of /shadcn-golden: runs the script-tier checks on every golden case.
#   ruby .claude/scripts/shadcn/golden_run.rb [case-id|all]
# Prints JSON: { results: [{ case, kind, status, detected, missed, false_positives, notes }] }
#   status PASS | FAIL | AGENT_PENDING (kind "agent": G1 part done, auditor still to run)
#          | PLANNER_PENDING (kind "planner": workspace prepared, planner agent still to run)
#   ruby .claude/scripts/shadcn/golden_run.rb planner-check <case-id>   # after the planner ran: validate its output
# Kinds: static, agent, scenario, extract, lint, state, planner, run (orchestrator protocol simulation), contract (required invocations in a command doc).
# Exit 0 when no script-tier case FAILs.

require "json"
require "open3"
require "fileutils"

GOLDEN = ".claude/shadcn-golden"
WORK = "tmp/shadcn-port/golden"
ORACLE = File.join(WORK, "oracle")
SCRIPTS = ".claude/scripts/shadcn"
want = ARGV.first || "all"

if want == "planner-check"
  id = ARGV[1] or abort("usage: planner-check <case-id>")
  exp_file = Dir[File.join(GOLDEN, "cases/#{id}*/expected.json")].first or abort("no such case #{id}")
  exp = JSON.parse(File.read(exp_file))
  cmd = ["ruby", File.join(SCRIPTS, "planner_check.rb"), "--component", exp["component"], "--root", File.join(WORK, "planner-out", exp["case"])]
  cmd += ["--min-scenarios", exp["min_scenarios"].to_s] if exp["min_scenarios"]
  cmd << "--require-dark" if exp["must_have_dark"]
  cmd += ["--require-steps", exp["must_have_step_kinds"].join(",")] if exp["must_have_step_kinds"]
  out, = Open3.capture2(*cmd)
  report = JSON.parse(out)
  puts JSON.pretty_generate(results: [{ case: exp["case"], kind: "planner", status: report["pass"] ? "PASS" : "FAIL",
                                        detected: report["findings"].map { |f| f["code"] }.uniq,
                                        missed: report["findings"].map { |f| "#{f['code']}: #{f['detail']}" },
                                        false_positives: [], notes: ["scenarios=#{report['scenario_count']}"] }])
  exit(report["pass"] ? 0 : 1)
end

FileUtils.rm_rf(WORK)
FileUtils.mkdir_p(File.join(ORACLE, "registry"))
FileUtils.cp(Dir[File.join(GOLDEN, "oracle-fixtures/registry/*.json")], File.join(ORACLE, "registry"))
_, err, st = Open3.capture3("ruby", File.join(SCRIPTS, "oracle_extract.rb"), "--offline", "--out", ORACLE)
abort("oracle extraction failed: #{err}") unless st.success?

def run_json(*cmd)
  out, = Open3.capture2(*cmd)
  JSON.parse(out)
end

def dig_path(obj, path)
  path.split(".").reduce(obj) { |o, k| o.is_a?(Array) ? o[k.to_i] : o&.[](k) }
end

def check_extract(assertions)
  graph = JSON.parse(File.read(File.join(ORACLE, "graph.json")))
  wave_of = graph["waves"].each_with_object({}) { |w, h| w["components"].each { |c| h[c] = w["wave"] } }
  assertions.filter_map do |a|
    if a["graph"] == "wave_before"
      next if wave_of[a["before"]] && wave_of[a["after"]] && wave_of[a["before"]] < wave_of[a["after"]]

      next "graph: #{a['before']} (wave #{wave_of[a['before']].inspect}) not before #{a['after']} (wave #{wave_of[a['after']].inspect})"
    end
    manifest = JSON.parse(File.read(File.join(ORACLE, "manifest", "#{a['manifest']}.json")))
    value = dig_path(manifest, a["path"])
    ok = true
    ok &&= value == a["equals"] if a.key?("equals")
    ok &&= (a["includes"] - Array(value)).empty? if a.key?("includes")
    ok &&= (a["keys_include"] - (value.is_a?(Hash) ? value.keys : [])).empty? if a.key?("keys_include")
    ok &&= Array(value).size >= a["min_count"] if a.key?("min_count")
    ok ? nil : "#{a['manifest']}.#{a['path']}: got #{value.inspect[0, 120]}"
  end
end

def port_state(work, *args)
  out, err, st = Open3.capture3("ruby", File.expand_path(File.join(SCRIPTS, "port_state.rb")), *args, chdir: work)
  [out, err, st]
end

def check_state(exp)
  work = File.join(WORK, "state-work")
  FileUtils.mkdir_p(File.join(work, "docs/shadcn-port"))
  FileUtils.cp_r(ORACLE, File.join(work, "docs/shadcn-port/oracle"))
  _, err, st = port_state(work, "init")
  return ["init failed: #{err.lines.first}"] unless st.success?

  state = -> { JSON.parse(File.read(File.join(work, "docs/shadcn-port/state.json")))["components"] }
  problems = []
  exp.fetch("assertions", []).each do |a|
    c = state.call[a["component"]]
    next problems << "#{a['component']} missing from state" unless c

    problems << "#{a['component']} wave #{c['wave']} != #{a['wave']}" if a["wave"] && c["wave"] != a["wave"]
    problems << "#{a['component']} kind #{c['kind']} != #{a['kind']}" if a["kind"] && c["kind"] != a["kind"]
    if a["wave_after"]
      other = state.call[a["wave_after"]]
      problems << "#{a['component']} (wave #{c['wave']}) not after #{a['wave_after']} (wave #{other && other['wave']})" unless other && c["wave"] > other["wave"]
    end
  end
  exp.fetch("flow", []).each_with_index do |op, i|
    label = "flow[#{i}] #{op.keys.first}"
    case op.keys.first
    when "next"
      out, = port_state(work, "next", "--concurrency", "20")
      got = JSON.parse(out)
      want = op["next"]
      names = got["batch"].map { |b| b["name"] }
      problems << "#{label}: wave #{got['wave'].inspect} != #{want['wave']}" if want.key?("wave") && got["wave"] != want["wave"]
      problems << "#{label}: kind #{got['kind'].inspect} != #{want['kind']}" if want["kind"] && got["kind"] != want["kind"]
      problems << "#{label}: batch #{names} lacks #{Array(want['includes']) - names}" if (Array(want["includes"]) - names).any?
      problems << "#{label}: expected done" if want["done"] && !got["done"]
    when "set" then port_state(work, "set", *op["set"].map(&:to_s))
    when "set_wave"
      wave, status = op["set_wave"]
      state.call.select { |_, c| c["wave"] == wave }.each_key { |n| port_state(work, "set", n, status) }
    when "reinit_preserves"
      before = state.call[op["reinit_preserves"]]["status"]
      port_state(work, "init")
      after = state.call[op["reinit_preserves"]]["status"]
      problems << "#{label}: #{op['reinit_preserves']} #{before} -> #{after}" unless before == after
    when "mutate_sha_then_reinit"
      f = File.join(work, "docs/shadcn-port/oracle/manifest/#{op['mutate_sha_then_reinit']}.json")
      m = JSON.parse(File.read(f))
      m["source_sha"] = "mutated"
      File.write(f, JSON.generate(m))
      port_state(work, "init")
      status = state.call[op["mutate_sha_then_reinit"]]["status"]
      problems << "#{label}: expected pending after oracle change, got #{status}" unless status == "pending"
    end
  end
  problems
end

# ---- orchestrator protocol simulation (kind "run") ---------------------------------------------
# Plays /shadcn-run's protocol against port_state.rb with scripted builder outcomes:
#   loop { next -> dispatch batch (set done|blocked, bump) -> checkpoint -> stop? }
# so the rules that used to live only in the command prose (wave order, dependency waiting, pilot stop,
# blocked-ratio stop, dispatch cap, resume) are tested for real.
class SimError < StandardError; end

def run_sim(exp, case_dir)
  work = File.join(WORK, "run-work", exp["case"])
  FileUtils.rm_rf(work)
  FileUtils.mkdir_p(File.join(work, "docs/shadcn-port"))
  oracle_src = exp["oracle"] == "case" ? File.join(case_dir, "files/oracle") : ORACLE
  FileUtils.cp_r(oracle_src, File.join(work, "docs/shadcn-port/oracle"))
  ps = ->(*args) { port_state(work, *args) }
  json = lambda do |*args|
    out, err, = ps.call(*args)
    JSON.parse(out)
  rescue JSON::ParserError
    raise SimError, "port_state.rb #{args.first} produced no JSON (#{err.lines.first.to_s.strip})"
  end
  _, err, st = ps.call("init", *Array(exp["init_args"]))
  return { problems: ["init failed: #{err.lines.first}"] } unless st.success?

  outcomes = exp.fetch("outcomes", {})
  trace = []
  stop = nil
  batches = 0
  halted = false
  completed = false
  waiting = {}
  step = lambda do
    300.times do
      nxt = json.call("next", "--concurrency", (exp["concurrency"] || 4).to_s)
      waiting = nxt["waiting"] || {}
      if nxt["done"]
        completed = true
        return
      end
      nxt["batch"].each do |b|
        out = outcomes[b["name"]] || exp["default_outcome"] || "done"
        status = out.is_a?(Hash) ? out.fetch("status", "done") : out
        bumps = out.is_a?(Hash) ? out.fetch("dispatches", 1) : 1
        trace << b["name"]
        ps.call("bump", bumps.to_s)
        ps.call("set", b["name"], %w[blocked built].include?(status) ? status : "done", "--note", "sim")
      end
      batches += 1
      cp = json.call("checkpoint")
      if cp["stop"]
        stop = cp["reason"]
        return
      end
      if exp["halt_after_batches"] && batches == exp["halt_after_batches"] && !halted
        halted = true
        return
      end
    end
    stop = "no_progress_guard"
  end
  step.call
  if halted && exp["resume"]
    ps.call("init", *Array(exp["init_args"])) # a restart re-initialises; progress must survive
    step.call
  end
  status = JSON.parse(File.read(File.join(work, "docs/shadcn-port/state.json")))["components"].transform_values { |c| c["status"] }
  { trace: trace, stop: stop, completed: completed, status: status, waiting: waiting, halted: halted }
end

def check_run(exp, case_dir)
  r = begin
    run_sim(exp, case_dir)
  rescue SimError => e
    return [e.message]
  end
  return r[:problems] if r[:problems]

  e = exp.fetch("expect", {})
  problems = []
  problems << "stop_reason #{r[:stop].inspect} != #{e['stop_reason'].inspect}" if e.key?("stop_reason") && r[:stop] != e["stop_reason"]
  problems << "run did not complete (stop=#{r[:stop].inspect})" if e["completed"] && !r[:completed]
  Array(e["dispatched_before"]).each do |a, b|
    ia = r[:trace].index(a)
    ib = r[:trace].index(b)
    problems << "#{a} must be dispatched before #{b} (trace: #{r[:trace].join(',')})" unless ia && ib && ia < ib
  end
  Array(e["never_dispatched"]).each { |n| problems << "#{n} must never be dispatched" if r[:trace].include?(n) }
  problems << "duplicate dispatches: #{r[:trace].tally.select { |_, n| n > 1 }.keys}" if e["dispatched_once"] && r[:trace].uniq.size != r[:trace].size
  (e["final_status"] || {}).each { |n, st| problems << "#{n} final status #{r[:status][n].inspect} != #{st}" unless r[:status][n] == st }
  (e["waiting"] || {}).each { |n, blocker| problems << "#{n} should be waiting on #{blocker}, got #{r[:waiting][n].inspect}" unless r[:waiting][n].to_s.include?(blocker) }
  problems
end

# ---- command contract (kind "contract") --------------------------------------------------------
# The orchestrator doc must keep invoking the scripts that judge. Deleting a step from the prose fails here.
def check_contract(exp)
  text = File.read(exp["file"])
  Array(exp["must_reference"]).reject { |needle| text.include?(needle) }.map { |n| "#{exp['file']} no longer references: #{n}" } +
    Array(exp["must_not_reference"]).select { |needle| text.include?(needle) }.map { |n| "#{exp['file']} still references: #{n}" }
end

def check_lint(exp, files)
  cmd = ["ruby", File.join(SCRIPTS, "command_lint.rb")]
  cmd += ["--docs", *files.select { |f| f.end_with?(".md") }] if exp["target"] == "docs"
  out, = Open3.capture2(*cmd)
  JSON.parse(out)
end

cases = Dir[File.join(GOLDEN, "cases/*")].sort.select { |d| want == "all" || File.basename(d).start_with?(want) }
results = cases.map do |dir|
  exp = JSON.parse(File.read(File.join(dir, "expected.json")))
  files = Dir[File.join(dir, "files/**/*")].select { |f| File.file?(f) }
  r = { case: exp["case"], kind: exp["kind"], detected: [], missed: [], false_positives: [], notes: [] }
  codes = []

  case exp["kind"]
  when "static", "agent"
    ruby_files = files.select { |f| f.include?("app/components/v2/") && f.end_with?(".rb") }
    if ruby_files.empty?
      r[:notes] << "no component .rb in case (static gate skipped)"
    else
      report = run_json("ruby", File.join(SCRIPTS, "static_gate.rb"), "--component", exp["component"], "--oracle", ORACLE,
                        "--files", ruby_files.join(","), "--deviations", File.join(WORK, "none"))
      codes = report["findings"].map { |f| f["code"] }.uniq
      r[:detected] = codes
    end
  when "scenario"
    report = run_json("ruby", File.join(SCRIPTS, "scenario_coverage.rb"), "--component", exp["component"], "--oracle", ORACLE,
                      "--scenarios", File.join(dir, "files/docs/shadcn-port/scenarios"))
    codes = report["gaps"].map { |g| g["code"] }.uniq
    r[:detected] = codes
  when "lint"
    report = check_lint(exp, files)
    codes = report["findings"].map { |f| f["code"] }.uniq
    r[:detected] = codes
    r[:notes] << "checked=#{report['checked']}"
  when "run"
    problems = check_run(exp, dir)
    r[:missed] = problems
    r[:status] = problems.empty? ? "PASS" : "FAIL"
    next r
  when "contract"
    problems = check_contract(exp)
    r[:missed] = problems
    r[:status] = problems.empty? ? "PASS" : "FAIL"
    next r
  when "state"
    problems = check_state(exp)
    r[:missed] = problems
    r[:status] = problems.empty? ? "PASS" : "FAIL"
    next r
  when "planner"
    out = File.join(WORK, "planner-out", exp["case"], "docs/shadcn-port")
    %w[specs scenarios deviations].each { |d| FileUtils.mkdir_p(File.join(out, d)) }
    FileUtils.cp_r(ORACLE, File.join(out, "oracle"))
    r[:status] = "PLANNER_PENDING"
    r[:notes] << "OUT_ROOT=#{File.join(WORK, 'planner-out', exp['case'])}"
    next r
  when "extract"
    failures = check_extract(exp["assertions"])
    r[:missed] = failures
    r[:status] = failures.empty? ? "PASS" : "FAIL"
    next r
  end

  r[:missed] = Array(exp["must_detect"]) - codes
  forbidden = Array(exp["must_not_detect"])
  r[:false_positives] = forbidden == ["*"] ? codes : codes & forbidden
  r[:status] =
    if exp["kind"] == "agent"
      r[:missed].empty? && r[:false_positives].empty? && (!exp["static_must_pass"] || codes.empty?) ? "AGENT_PENDING" : "FAIL"
    else
      r[:missed].empty? && r[:false_positives].empty? ? "PASS" : "FAIL"
    end
  r
end

puts JSON.pretty_generate(results: results)
exit(results.any? { |x| x[:status] == "FAIL" } ? 1 : 0)
