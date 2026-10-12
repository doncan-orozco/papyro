#!/usr/bin/env ruby
# frozen_string_literal: true

# Mechanical gate for a gem that lives in (or was extracted from) a host Rails app: proves the gem stands alone and is packaged
# like a gem. Deterministic, no network, no bundler context needed.
#
#   ruby .claude/scripts/gem/gem_check.rb --gem-dir gems/phlex-shadcn [--host-dir .] [--rails-files 'lib/**/engine.rb,lib/**/railtie.rb,lib/generators/**,lib/tasks/**']
#
# Prints JSON { gem_dir, pass, findings: [{ code, file, line, detail }] }; exit 1 when findings, 2 on usage error.
#
# Codes:
#   GEM_NOT_FOUND            gem dir missing
#   GEMSPEC_MISSING          no *.gemspec in the gem dir
#   GEMSPEC_UNLOADABLE       the gemspec raises when loaded
#   GEMSPEC_FIELD            required metadata missing (name, version, summary, description, authors, license, required_ruby_version, homepage, source_code_uri, changelog_uri)
#   GEMSPEC_FILES            spec.files packages development material (tests, dev kit, docs apps, node_modules, tmp, oracle)
#   GEMSPEC_LICENSE          LICENSE file missing
#   GEM_NOTICES              third-party notices missing for code derived from shadcn/ui, Radix or Lucide (THIRD_PARTY_NOTICES*)
#   GEM_NO_TESTS             no test/ or spec/ directory in the gem
#   GEM_HOST_CONSTANT        Ruby code references a constant that only the host app defines
#   GEM_RAILS_REFERENCE      Rails/ActionView/ActionController/ActiveRecord referenced outside the Rails integration files
#   GEM_UNDECLARED_DEPENDENCY a library namespace is used but the gemspec does not declare its gem
#   GEM_ACTIVESUPPORT_EXT    ActiveSupport core extensions used while activesupport is not a declared dependency and not required
#   GEM_ESCAPES_ROOT         require_relative / File path reaching outside the gem directory, or a host path hard-coded

require "json"
require "optparse"
require "rubygems"

opts = { host_dir: ".", rails_files: %w[lib/**/engine.rb lib/**/railtie.rb lib/generators/** lib/tasks/**] }
OptionParser.new do |o|
  o.on("--gem-dir DIR") { |v| opts[:gem_dir] = v }
  o.on("--host-dir DIR") { |v| opts[:host_dir] = v }
  o.on("--rails-files LIST") { |v| opts[:rails_files] = v.split(",") }
end.parse!
abort("usage: --gem-dir DIR [--host-dir DIR]") unless opts[:gem_dir]

gem_dir = File.expand_path(opts[:gem_dir])
host_dir = File.expand_path(opts[:host_dir])
findings = []
add = ->(code, file, line, detail) { findings << { code: code, file: file && file.delete_prefix("#{gem_dir}/"), line: line, detail: detail } }
finish = lambda do |code|
  puts JSON.pretty_generate(gem_dir: opts[:gem_dir], pass: findings.empty?, findings: findings)
  exit(code)
end

unless Dir.exist?(gem_dir)
  add.call("GEM_NOT_FOUND", nil, nil, gem_dir)
  finish.call(1)
end

# ---- gemspec ----------------------------------------------------------------------------------------------------
specs = Dir[File.join(gem_dir, "*.gemspec")]
spec = nil
if specs.empty?
  add.call("GEMSPEC_MISSING", nil, nil, "no *.gemspec in #{opts[:gem_dir]}")
else
  begin
    Dir.chdir(gem_dir) { spec = Gem::Specification.load(specs.first) }
    add.call("GEMSPEC_UNLOADABLE", specs.first, nil, "Gem::Specification.load returned nil (see `ruby -e 'p Gem::Specification.load(\"#{specs.first}\")'`)") unless spec
  rescue StandardError, ScriptError => e
    add.call("GEMSPEC_UNLOADABLE", specs.first, nil, "#{e.class}: #{e.message}")
  end
end

DEV_MATERIAL = %r{\A(?:test|spec|dev|docs?|oracle|node_modules|tmp|react-[\w-]+|\.github|\.claude|\.ai|bin/ci|Gemfile\.lock)(?:/|\z)}
REQUIRED_METADATA = %w[source_code_uri changelog_uri].freeze

if spec
  { "name" => spec.name, "version" => spec.version.to_s, "summary" => spec.summary, "description" => spec.description, "authors" => spec.authors,
    "license" => spec.licenses, "homepage" => spec.homepage }.each do |field, value|
    add.call("GEMSPEC_FIELD", specs.first, nil, "#{field} is missing or empty") if value.nil? || (value.respond_to?(:empty?) && value.empty?) || value.to_s == "0"
  end
  add.call("GEMSPEC_FIELD", specs.first, nil, "required_ruby_version is not set (it defaults to >= 0)") if spec.required_ruby_version.to_s == ">= 0"
  REQUIRED_METADATA.each { |m| add.call("GEMSPEC_FIELD", specs.first, nil, "metadata[#{m}] is missing") unless spec.metadata[m] }
  packaged = spec.files.select { |f| f.match?(DEV_MATERIAL) }
  add.call("GEMSPEC_FILES", specs.first, nil, "packages development material: #{packaged.first(6).join(', ')}#{packaged.size > 6 ? ' ...' : ''}") if packaged.any?
end
add.call("GEMSPEC_LICENSE", nil, nil, "no LICENSE / LICENSE.txt / MIT-LICENSE") if Dir[File.join(gem_dir, "{LICENSE,LICENSE.*,MIT-LICENSE,COPYING}")].empty?
add.call("GEM_NO_TESTS", nil, nil, "no test/ or spec/ directory") unless Dir.exist?(File.join(gem_dir, "test")) || Dir.exist?(File.join(gem_dir, "spec"))

# ---- Ruby sources ------------------------------------------------------------------------------------------------
lib_files = Dir[File.join(gem_dir, "{lib,app}/**/*.rb")]
rails_glob = opts[:rails_files].flat_map { |g| Dir[File.join(gem_dir, g)] }.select { |f| File.file?(f) }
code_of = ->(file) { File.readlines(file).each_with_index.map { |l, i| [ i + 1, l.sub(/(?<!\S)#(?![{@$]).*\z/, "") ] } }
sources = lib_files.to_h { |f| [ f, code_of.call(f) ] }
all_code = sources.values.flatten(1).map(&:last).join

# Third-party code notices: required as soon as the gem ships things derived from these projects.
derived = { "shadcn/ui" => /shadcn/i, "Radix" => /radix/i, "Lucide" => /lucide/i }.select { |_, re| all_code.match?(re) }
notices = Dir[File.join(gem_dir, "THIRD_PARTY_NOTICES*")].map { |f| File.read(f) }.join("\n")
derived.each_key do |name|
  add.call("GEM_NOTICES", nil, nil, "code derived from #{name} but no mention in THIRD_PARTY_NOTICES") unless notices.match?(/#{Regexp.escape(name)}/i)
end

# Host constants: top-level namespaces declared in the host's own app/ and lib/ that the gem does not declare itself.
# Host: only TOP-LEVEL declarations count (column 0); a nested `class Accordion` inside the host's namespace is not reachable from the gem.
# Gem: any declaration counts, so a name the gem defines itself is trusted to resolve lexically.
host_top_level = ->(files) { files.flat_map { |f| File.read(f).scan(/^(?:class|module)\s+([A-Z]\w*)/).flatten }.uniq }
declared_anywhere = ->(files) { files.flat_map { |f| File.read(f).scan(/^\s*(?:class|module)\s+([A-Z]\w*)/).flatten }.uniq }
host_files = Dir[File.join(host_dir, "{app,lib}/**/*.rb")].reject { |f| f.start_with?("#{gem_dir}/") }
generic = %w[Rails ActiveSupport ActionView ActionController ActiveRecord ActiveModel Phlex Kernel Object Module Class Struct Data Set JSON Time Date String Symbol Hash Array Comparable Enumerable]
host_constants = host_top_level.call(host_files) - declared_anywhere.call(Dir[File.join(gem_dir, "**/*.rb")]) - generic

sources.each do |file, lines|
  lines.each do |n, text|
    host_constants.each do |const|
      add.call("GEM_HOST_CONSTANT", file, n, "references #{const}, defined by the host app") if text.match?(/(?<![\w:])#{const}(?:::|\.\w)/)
    end
    if (rel = text[/require_relative\s+["']((?:\.\.\/)+)/, 1])
      depth = File.dirname(file.delete_prefix("#{gem_dir}/")).split("/").reject { |part| part == "." }.size
      add.call("GEM_ESCAPES_ROOT", file, n, "require_relative leaves the gem directory (#{rel.scan('../').size} levels up from depth #{depth})") if rel.scan("../").size > depth
    end
    add.call("GEM_ESCAPES_ROOT", file, n, "hard-coded host path (app/... or Rails.root)") if text.match?(/["'](?:\.\/)?app\/(?:assets|javascript|views|components)\//) && !rails_glob.include?(file)
  end
end

# Rails / ActiveSupport use outside the integration layer.
rails_re = /(?<![\w:])(?:Rails|ActionView|ActionController|ActiveRecord|ActionDispatch)\b/
sources.each do |file, lines|
  next if rails_glob.include?(file)

  lines.each { |n, text| add.call("GEM_RAILS_REFERENCE", file, n, "#{text[rails_re]} used outside the Rails integration files (engine/railtie/generators/tasks)") if text.match?(rails_re) }
end

runtime = spec ? spec.runtime_dependencies.map(&:name) : []
# Library namespaces and the gem that provides them (the gem's own Phlex::Shadcn namespace is not a use of phlex).
USES = {
  "activesupport" => /(?<![\w:])ActiveSupport(?:::|\.)/,
  "tailwind_merge" => /(?<![\w:])TailwindMerge(?:::|\.)/,
  "zeitwerk" => /(?<![\w:])Zeitwerk(?:::|\.)/,
  "phlex" => /(?<![\w:])Phlex::(?:HTML|SGML|Kit|Helpers)\b/,
  "phlex-rails" => /(?<![\w:])Phlex::Rails\b/
}.freeze
if spec
  USES.each do |dep, re|
    next if runtime.include?(dep) || (dep == "phlex" && runtime.include?("phlex-rails"))

    hit = sources.find { |f, lines| !rails_glob.include?(f) && lines.any? { |_, t| t.match?(re) } }
    add.call("GEM_UNDECLARED_DEPENDENCY", hit[0], nil, "#{dep} is used but the gemspec has no runtime dependency on it") if hit
  end
end

EXT = /\.(?:deep_merge|presence|present\?|blank\?|underscore|dasherize|camelize|titleize|html_safe|squish|except|slice!?|to_sentence|with_indifferent_access|symbolize_keys|stringify_keys|try|in\?)\b/
require_as = all_code.match?(/require\s+["']active_support/)
unless runtime.include?("activesupport") || require_as
  uses = sources.flat_map { |f, lines| lines.filter_map { |n, t| [ f, n, t[EXT] ] if t.match?(EXT) && !t.match?(/\.except\(/) } }
  uses.first(3).each { |f, n, ext| add.call("GEM_ACTIVESUPPORT_EXT", f, n, "#{ext} is an ActiveSupport extension; declare activesupport or use plain Ruby") }
  add.call("GEM_ACTIVESUPPORT_EXT", nil, nil, "#{uses.size} ActiveSupport extension call(s) in total") if uses.size > 3
end

finish.call(findings.empty? ? 0 : 1)
