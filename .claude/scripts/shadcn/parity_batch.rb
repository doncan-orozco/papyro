#!/usr/bin/env ruby
# frozen_string_literal: true

# Browser gates for a list of components in one call: ensures Playwright and the dev servers, runs G2/G3 for each component
# (and, on request, G2b DX helpers and G4 themes), writes the raw reports and stops the servers it started.
#
#   ruby .claude/scripts/shadcn/parity_batch.rb --components button,card          # G2 + G3
#   ruby .claude/scripts/shadcn/parity_batch.rb --components all --dx --themes slate,stone,zinc-radius0
#   ruby .claude/scripts/shadcn/parity_batch.rb --components dialog --no-servers   # servers already running (servers.rb status)
#
# --components LIST|all  comma list of component names, or every scenario file that does not start with `_`
# --dx                   also G2b: scenarios starting default / variant- / example__ (cap 25) through the yielded-root helpers,
#                        only for components that have helpers (spec_helpers.rb --print)
# --themes LIST          also G4: each theme preset on the scenarios starting variant- or default (cap 12), plus one --dark run
# --no-servers           neither ensure Playwright nor start/stop servers (they must already be running)
# --out DIR              reports go to DIR/<component>/{g2,g2b,g4-<theme>,g4-dark}.json (default tmp/shadcn-port)
#
# Prints JSON { pass, servers_started, components: { name => { gates => { gate => { pass, diffs } } } } } and exits 1 when any gate fails
# or the environment cannot run the gates (exit 2).

require "fileutils"
require "json"
require "open3"
require "optparse"

SCRIPTS = ".claude/scripts/shadcn"
SCENARIOS = "docs/shadcn-port/scenarios"
CATALOG = "react-shadcn-catalog"
DX_PREFIXES = %w[default variant- example__].freeze
THEME_PREFIXES = %w[variant- default].freeze

opts = { components: nil, dx: false, themes: [], servers: true, out: "tmp/shadcn-port" }
OptionParser.new do |o|
  o.on("--components LIST") { |v| opts[:components] = v }
  o.on("--dx") { opts[:dx] = true }
  o.on("--themes LIST") { |v| opts[:themes] = v.split(",").map(&:strip).reject(&:empty?) }
  o.on("--no-servers") { opts[:servers] = false }
  o.on("--out DIR") { |v| opts[:out] = v }
end.parse!
abort("usage: --components a,b|all [--dx] [--themes slate,stone] [--no-servers] [--out DIR]") unless opts[:components]

def scenario_ids(component, prefixes, cap)
  file = File.join(SCENARIOS, "#{component}.json")
  return [] unless File.exist?(file)

  ids = JSON.parse(File.read(file)).fetch("scenarios", []).map { |s| s["id"] }.compact
  ids.select { |id| prefixes.any? { |prefix| id.start_with?(prefix) } }.first(cap)
end

def helpers?(component)
  out, = Open3.capture2("ruby", File.join(SCRIPTS, "spec_helpers.rb"), "--print", "--component", component)
  (JSON.parse(out[/\{.*\}/m] || "{}")["helpers"] || []).any?
rescue JSON::ParserError
  false
end

def run_parity(component, out_file, *flags)
  out, = Open3.capture2("node", File.expand_path(File.join(SCRIPTS, "parity_run.mjs")), "--component", component, *flags, chdir: CATALOG)
  FileUtils.mkdir_p(File.dirname(out_file))
  File.write(out_file, out)
  report = JSON.parse(out[/\{.*\}/m] || "{}")
  { "pass" => report["pass"] == true, "diffs" => Array(report["diffs"]).size, "report" => out_file }
rescue JSON::ParserError
  { "pass" => false, "diffs" => 0, "error" => "unparseable output", "report" => out_file }
end

components =
  if opts[:components] == "all"
    Dir[File.join(SCENARIOS, "*.json")].map { |f| File.basename(f, ".json") }.reject { |n| n.start_with?("_") }.sort
  else
    opts[:components].split(",").map(&:strip).reject(&:empty?)
  end
abort("no components") if components.empty?

def environment_failure(message)
  puts JSON.pretty_generate(pass: false, error: message)
  exit 2
end

servers_started = false
if opts[:servers]
  _, status = Open3.capture2e("ruby", File.join(SCRIPTS, "playwright_ensure.rb"))
  environment_failure("no usable Playwright browser (run playwright_ensure.rb)") unless status.success?

  out, status = Open3.capture2("ruby", File.join(SCRIPTS, "servers.rb"), "start")
  started = JSON.parse(out[/\{.*\}/m] || "{}")
  environment_failure("dev servers did not start (see tmp/shadcn-port/{rails,vite}.log)") unless status.success?
  servers_started = !started["reused"]
end

results = {}
begin
  components.each do |component|
    dir = File.join(opts[:out], component)
    gates = {}
    gates["g2"] = run_parity(component, File.join(dir, "g2.json"))
    if opts[:dx] && helpers?(component)
      ids = scenario_ids(component, DX_PREFIXES, 25)
      gates["g2b"] = run_parity(component, File.join(dir, "g2b.json"), "--dx", "helpers", "--only", ids.join(",")) if ids.any?
    end
    theme_ids = scenario_ids(component, THEME_PREFIXES, 12)
    if theme_ids.any?
      opts[:themes].each { |theme| gates["g4-#{theme}"] = run_parity(component, File.join(dir, "g4-#{theme}.json"), "--theme", theme, "--only", theme_ids.join(",")) }
      gates["g4-dark"] = run_parity(component, File.join(dir, "g4-dark.json"), "--dark", "--only", theme_ids.join(",")) if opts[:themes].any?
    end
    results[component] = { "pass" => gates.values.all? { |g| g["pass"] }, "gates" => gates }
  end
ensure
  system("ruby", File.join(SCRIPTS, "servers.rb"), "stop", out: File::NULL) if servers_started
end

pass = results.values.all? { |r| r["pass"] }
puts JSON.pretty_generate(pass: pass, servers_started: servers_started, components: results)
exit(pass ? 0 : 1)
