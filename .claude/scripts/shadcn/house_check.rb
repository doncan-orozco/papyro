#!/usr/bin/env ruby
# frozen_string_literal: true

# Gate G5 (house), mechanical part: library-wide consistency. No browser, no LLM.
#   ruby .claude/scripts/shadcn/house_check.rb [--static-all]
# --static-all additionally runs the G1 static gate for every component whose state is `done`.
# Exit 1 when any finding exists. Prints JSON { pass, findings: [{ code, detail }] }.

require "json"
require "open3"
require "optparse"

opts = {}
OptionParser.new { |o| o.on("--static-all") { opts[:static_all] = true } }.parse!

findings = []
add = ->(code, detail) { findings << { code: code, detail: detail } }

state_file = "docs/shadcn-port/state.json"
state = File.exist?(state_file) ? JSON.parse(File.read(state_file)) : abort("no #{state_file}")
done = state["components"].select { |n, c| c["status"] == "done" && !n.start_with?("_") }.keys

done.each do |name|
  manifest = JSON.parse(File.read("docs/shadcn-port/oracle/manifest/#{name}.json"))
  ruby_name = name.tr("-", "_")
  add.call("G5_FILE_MISSING", "app/components/v2/#{ruby_name}.rb") unless File.exist?("app/components/v2/#{ruby_name}.rb")
  add.call("G5_SPEC_MISSING", "docs/shadcn-port/specs/#{name}.md") unless File.exist?("docs/shadcn-port/specs/#{name}.md")
  add.call("G5_SCENARIOS_MISSING", "docs/shadcn-port/scenarios/#{name}.json") unless File.exist?("docs/shadcn-port/scenarios/#{name}.json")
  interactive = manifest["tier"] != "static"
  controller = "app/javascript/controllers/v2/#{ruby_name}_controller.js"
  add.call("G5_CONTROLLER_MISSING", controller) if interactive && !File.exist?(controller) && manifest["tier"] != "client"
  if opts[:static_all]
    out, = Open3.capture2("ruby", ".claude/scripts/shadcn/static_gate.rb", "--component", name)
    add.call("G5_REGRESSION_G1", name) unless JSON.parse(out)["pass"]
  end
end

# Orphan controllers: a ui controller without a component in the manifest set (base/theme helpers excepted).
known = Dir["docs/shadcn-port/oracle/manifest/*.json"].map { |f| File.basename(f, ".json").tr("-", "_") }
Dir["app/javascript/controllers/v2/*_controller.js"].each do |f|
  base = File.basename(f, "_controller.js")
  add.call("G5_ORPHAN_CONTROLLER", f) unless known.include?(base) || %w[base theme].include?(base)
end

# Deviations register must list every deviations file, and vice versa.
register = File.exist?("docs/shadcn-port/DEVIATIONS.md") ? File.read("docs/shadcn-port/DEVIATIONS.md") : ""
Dir["docs/shadcn-port/deviations/*.json"].each do |f|
  name = File.basename(f, ".json")
  add.call("G5_DEVIATION_UNREGISTERED", name) unless register.include?("`#{name}`")
end

if File.exist?("react-shadcn-catalog/node_modules/tailwind-merge/package.json") && Dir.exist?("docs/shadcn-port/oracle/src")
  out, status = Open3.capture2("ruby", ".claude/scripts/shadcn/cn_differential.rb", "--show", "3")
  summary = (JSON.parse(out) rescue {}).slice("js_version", "ruby_version", "mismatch_count", "classes_that_differ")
  add.call("G5_CN_DIFFERENTIAL", "oracle cn (JS twMerge) and port cn (Ruby tailwind_merge) disagree: #{summary}") unless status.success?
end

catalog_css = "react-shadcn-catalog/src/index.css"
if File.exist?(catalog_css) && File.read(catalog_css).match?(/^\s*(:root|\.dark)\b|@theme/)
  add.call("G5_CATALOG_CSS", "#{catalog_css} must only import tailwindcss, tw-animate-css and the host theme (the shadcn CLI appends HSL variables)")
end

importmap = File.exist?("config/importmap.rb") ? File.read("config/importmap.rb") : ""
catalog_fui = "react-shadcn-catalog/node_modules/@floating-ui/dom/package.json"
if File.exist?(catalog_fui) && (pinned = importmap[/pin "@floating-ui\/dom".*?# @([\d.]+)/, 1])
  catalog_version = JSON.parse(File.read(catalog_fui))["version"]
  add.call("G5_FLOATING_UI_VERSION", "importmap pins @floating-ui/dom #{pinned} but the catalog (oracle) runs #{catalog_version}: re-pin") unless pinned == catalog_version
end
add.call("G5_IMPORTMAP", "config/importmap.rb lacks pin_all_from \"app/javascript/v2\"") if Dir.exist?("app/javascript/v2") && !importmap.include?("app/javascript/v2")

require_relative "../../../lib/shadcn/theme"
if File.exist?("app/assets/tailwind/theme/theme.css")
  theme = Shadcn::Theme.check
  theme[:errors].each { |e| add.call("G5_THEME_INVALID", e) }
  if File.exist?("app/assets/tailwind/theme/tokens.css") && Dir.exist?("docs/shadcn-port/oracle/manifest")
    out, status = Open3.capture2("ruby", ".claude/scripts/shadcn/theme_sync.rb", "--check-tokens")
    add.call("G5_TOKENS_DRIFT", out.strip[0, 400]) unless status.success?
  end
else
  add.call("G5_THEME_MISSING", "app/assets/tailwind/theme/theme.css")
end

puts JSON.pretty_generate(pass: findings.empty?, components_checked: done.size, findings: findings)
exit(findings.empty? ? 0 : 1)
