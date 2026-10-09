#!/usr/bin/env ruby
# frozen_string_literal: true

# Resumable run state for /shadcn-run. The orchestrator asks this script what to do next
# instead of reasoning about waves itself.
#
#   ruby .claude/scripts/shadcn/port_state.rb init [--only a,b] [--pilot a,b,c]
#   ruby .claude/scripts/shadcn/port_state.rb next [--concurrency 4]     # JSON batch for the lowest unfinished wave
#   ruby .claude/scripts/shadcn/port_state.rb set NAME STATUS [--note TXT] [--iteration N] [--sha SHA]
#   ruby .claude/scripts/shadcn/port_state.rb summary [--json]
#   ruby .claude/scripts/shadcn/port_state.rb reset NAME|all
#
# Statuses: pending -> planned -> built -> done | blocked   (fixing is a transient label of built)
# Waves: 0 infra (theme, harness, primitives), 1 pilot (one per behavior family), 2.. fan-out by oracle dependency layers.

require "json"
require "optparse"
require "time"
require "fileutils"

STATE = "docs/shadcn-port/state.json"
GRAPH = "docs/shadcn-port/oracle/graph.json"
STATUSES = %w[pending planned built done blocked].freeze
DEFAULT_PILOT = %w[button switch dialog tooltip dropdown-menu select].freeze
INFRA = [
  { "name" => "_theme", "owns" => ["app/assets/tailwind/application.css", "app/assets/tailwind/foundation/**", "app/assets/tailwind/theme/** (bug fixes only)", "app/assets/tailwind/vendor/**", "app/javascript/controllers/v2/theme_controller.js", "react-shadcn-catalog/src/index.css", "react-shadcn-catalog/src/index.css.init", "lib/shadcn/**", "lib/tasks/theme.rake", "test/lib/shadcn/**"] },
  { "name" => "_harness", "owns" => ["app/components/parity/**", "app/views/design_system/parity/**", "config/routes.rb (parity route only)", "react-shadcn-catalog/src/parity/**", "react-shadcn-catalog/vite.config.ts", "react-shadcn-catalog/package.json"] },
  { "name" => "_primitives", "owns" => ["app/javascript/v2/primitives/**", "config/importmap.rb (pin_all_from v2)", "react-shadcn-catalog/src/parity/primitives/**", "docs/shadcn-port/scenarios/_primitives-*.json"] },
  { "name" => "_base", "owns" => ["app/components/v2/base.rb", "test/components/v2/base_test.rb"] },
  { "name" => "_icons", "owns" => ["app/components/v2/icon.rb", "app/components/v2/icons/**"] },
].freeze

def load_state = JSON.parse(File.read(STATE))
def save_state(s) = File.write(STATE, JSON.pretty_generate(s))

def component_entry(name, tier, wave)
  { "status" => "pending", "tier" => tier, "wave" => wave, "iteration" => 0, "note" => nil, "last_green_sha" => nil, "updated_at" => Time.now.utc.iso8601 }
end

def init(opts)
  graph = JSON.parse(File.read(GRAPH))
  names = graph["waves"].flat_map { |w| w["components"] }
  names &= opts[:only] if opts[:only]
  pilot = (opts[:pilot] || DEFAULT_PILOT) & names
  layers = graph["waves"].to_h { |w| [w["wave"], w["components"] & names] }

  components = {}
  INFRA.each { |i| components[i["name"]] = component_entry(i["name"], "infra", 0).merge("owns" => i["owns"], "kind" => "infra") }
  pilot.each { |n| components[n] = component_entry(n, graph["tiers"][n], 1).merge("kind" => "pilot") }
  fix_dependency_waves!(components, graph["nodes"]) # pilots may need mini-waves (button before dialog)
  base = components.values.select { |c| c["kind"] == "pilot" }.map { |c| c["wave"] }.max || 0
  layers.each do |layer, list|
    (list - pilot).each { |n| components[n] = component_entry(n, graph["tiers"][n], base + layer).merge("kind" => "fanout") }
  end
  fix_dependency_waves!(components, graph["nodes"]) # dependencies always win

  FileUtils.mkdir_p(File.dirname(STATE))
  save_state("created_at" => Time.now.utc.iso8601, "oracle" => JSON.parse(File.read(File.join(File.dirname(GRAPH), "VERSION.json"))), "components" => components)
  warn "state: #{components.size} items, #{components.values.map { |c| c['wave'] }.max + 1} waves"
end

# Guarantee wave(component) > wave(each dependency present in the run).
def fix_dependency_waves!(components, nodes)
  changed = true
  while changed
    changed = false
    components.each do |name, c|
      next if c["tier"] == "infra"

      (nodes[name] || []).each do |dep|
        next unless components[dep]
        next if components[dep]["wave"] < c["wave"]

        c["wave"] = components[dep]["wave"] + 1
        changed = true
      end
    end
  end
end

def current_wave(state)
  open = state["components"].select { |_, c| %w[pending planned built].include?(c["status"]) }
  open.values.map { |c| c["wave"] }.min
end

def next_batch(state, concurrency)
  wave = current_wave(state)
  return { "wave" => nil, "batch" => [], "done" => true } if wave.nil?

  open = state["components"].select { |_, c| c["wave"] == wave && %w[pending planned built].include?(c["status"]) }
  blocked_dep = state["components"].select { |_, c| c["wave"] < wave && c["status"] == "blocked" }.keys
  batch = open.keys.first(concurrency)
  {
    "wave" => wave,
    "kind" => open.values.first["kind"],
    "batch" => batch.map { |n| { "name" => n, "status" => open[n]["status"], "iteration" => open[n]["iteration"], "owns" => open[n]["owns"] }.compact },
    "remaining_in_wave" => open.size - batch.size,
    "blocked_earlier" => blocked_dep,
    "done" => false,
  }
end

def summary(state, json)
  rows = state["components"].map { |n, c| [c["wave"], n, c["status"], c["iteration"], c["note"]] }.sort_by { |r| [r[0], r[1]] }
  return puts(JSON.pretty_generate(rows.map { |w, n, s, i, note| { wave: w, name: n, status: s, iteration: i, note: note } })) if json

  tally = state["components"].values.map { |c| c["status"] }.tally
  puts "wave  component             status    iter  note"
  rows.each { |w, n, s, i, note| puts format("%-5s %-21s %-9s %-5s %s", w, n, s, i, note.to_s[0, 70]) }
  puts "\n#{tally.map { |k, v| "#{k}=#{v}" }.join('  ')}"
end

cmd = ARGV.shift
opts = {}
parser = OptionParser.new do |o|
  o.on("--only LIST") { |v| opts[:only] = v.split(",") }
  o.on("--pilot LIST") { |v| opts[:pilot] = v.split(",") }
  o.on("--concurrency N", Integer) { |v| opts[:concurrency] = v }
  o.on("--note TXT") { |v| opts[:note] = v }
  o.on("--iteration N", Integer) { |v| opts[:iteration] = v }
  o.on("--sha SHA") { |v| opts[:sha] = v }
  o.on("--json") { opts[:json] = true }
end
parser.parse!

case cmd
when "init" then init(opts)
when "next" then puts JSON.pretty_generate(next_batch(load_state, opts[:concurrency] || 4))
when "set"
  name, status = ARGV
  abort("status must be one of #{STATUSES.join(', ')}") unless STATUSES.include?(status)
  state = load_state
  abort("unknown component #{name}") unless state["components"][name]
  c = state["components"][name]
  c["status"] = status
  c["note"] = opts[:note] if opts.key?(:note)
  c["iteration"] = opts[:iteration] if opts[:iteration]
  c["last_green_sha"] = opts[:sha] if opts[:sha]
  c["updated_at"] = Time.now.utc.iso8601
  save_state(state)
when "summary" then summary(load_state, opts[:json])
when "reset"
  state = load_state
  targets = ARGV.first == "all" ? state["components"].keys : ARGV
  targets.each { |n| state["components"][n]&.merge!("status" => "pending", "iteration" => 0, "note" => nil) }
  save_state(state)
else
  abort("usage: init | next | set NAME STATUS | summary | reset NAME|all")
end
