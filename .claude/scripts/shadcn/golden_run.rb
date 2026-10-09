#!/usr/bin/env ruby
# frozen_string_literal: true

# Deterministic half of /shadcn-golden: runs the script-tier checks on every golden case.
#   ruby .claude/scripts/shadcn/golden_run.rb [case-id|all]
# Prints JSON: { results: [{ case, kind, status, detected, missed, false_positives, notes }] }
#   status PASS | FAIL | AGENT_PENDING (kind "agent": G1 part done, auditor still to run)
# Exit 0 when no script-tier case FAILs.

require "json"
require "open3"
require "fileutils"

GOLDEN = ".claude/shadcn-golden"
WORK = "tmp/shadcn-port/golden"
ORACLE = File.join(WORK, "oracle")
SCRIPTS = ".claude/scripts/shadcn"
want = ARGV.first || "all"

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
