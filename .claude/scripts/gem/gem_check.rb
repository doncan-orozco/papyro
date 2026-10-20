#!/usr/bin/env ruby
# frozen_string_literal: true

# Mechanical gate for a gem that lives in (or was extracted from) a host Rails app: proves the gem stands alone and is packaged
# like a gem. Deterministic, no network, no bundler context needed.
#
#   ruby .claude/scripts/gem/gem_check.rb --gem-dir gems/phlex-shadcn [--host-dir .] [--rails-files 'lib/**/engine.rb,lib/**/railtie.rb,lib/generators/**/*,lib/tasks/**/*']
#
# Prints JSON { gem_dir, pass, findings: [{ code, file, line, detail }] }; exit 1 when findings, 2 on usage error.
#
# Codes:
#   GEM_NOT_FOUND            gem dir missing
#   GEMSPEC_MISSING          no *.gemspec in the gem dir
#   GEMSPEC_UNLOADABLE       the gemspec raises when loaded
#   GEMSPEC_FIELD            required metadata missing (name, version, summary, description, authors, license, required_ruby_version, homepage, source_code_uri, changelog_uri)
#   GEMSPEC_FILES            spec.files packages development material (tests, dev kit, docs apps, node_modules, tmp, oracle)
#   GEMSPEC_DEV_MATERIAL     spec.files packages a dev-only Stimulus controller (`_probe_*` parity probes, `theme_panel`): every consumer would pin and register it
#   GEMSPEC_METADATA         a metadata URI (homepage, source_code_uri, changelog_uri, ...) is not a well-formed http(s) URI, or a GitHub changelog_uri/source_code_uri
#                            does not have the shape https://github.com/<owner>/<repo>/(blob|tree)/<ref>/<path>
#                            (a bare https://github.com/<owner>/<repo> is accepted for source_code_uri)
#   GEMSPEC_LICENSE          LICENSE file missing
#   GEM_NOTICES              third-party notices missing for code derived from shadcn/ui, Radix or Lucide (THIRD_PARTY_NOTICES*)
#   GEM_NO_TESTS             no test/ or spec/ directory in the gem
#   GEM_HOST_CONSTANT        Ruby code references a constant that only the host app defines
#   GEM_RAILS_REFERENCE      Rails/ActionView/ActionController/ActiveRecord referenced outside the Rails integration files
#   GEM_UNDECLARED_DEPENDENCY a library namespace is used but the gemspec does not declare its gem
#   GEM_ACTIVESUPPORT_EXT    ActiveSupport core extensions used while activesupport is not a declared dependency and not required
#   GEM_ESCAPES_ROOT         require_relative / File path reaching outside the gem directory, or a host path hard-coded
#
# Intentional host paths (the one allowlist): a gem file whose job is to INSPECT the host (the doctor) may name a host path
# (`app/assets/...`) when the SAME line carries the marker below. Nothing else is accepted: not building the path with
# File.join/split strings to dodge the rule, not a marker elsewhere in the file.
#
#   DEFAULT_CSS = "app/assets/tailwind/application.css" # gem_check:allow GEM_ESCAPES_ROOT -- the doctor reads the host stylesheet
#
#   - exact rule id: only GEM_ESCAPES_ROOT's hard-coded host path check can be allowed (never require_relative leaving the gem,
#     never another code); the id must be written out;
#   - a reason after `--` is required (a bare marker does not count);
#   - scope: only files matching HOST_PATH_ALLOW_GLOBS (lib/phlex/shadcn/doctor/**/*.rb). The Rails integration files
#     (generators, rake tasks, engine, railtie) are already exempt from this check and need no marker. The same literal in any
#     other file keeps failing, marker or not.
#   Decision: gems/phlex-shadcn/dev/decisions/gem-check-host-paths.md

require "json"
require "optparse"
require "rubygems"
require "uri"

# Files that inspect the host on purpose and may carry a `# gem_check:allow GEM_ESCAPES_ROOT -- <reason>` marker (see header).
HOST_PATH_ALLOW_GLOBS = %w[lib/phlex/shadcn/doctor/**/*.rb].freeze
HOST_PATH_ALLOW_MARKER = /#\s*gem_check:allow\s+GEM_ESCAPES_ROOT\s+--\s+\S/

opts = { host_dir: ".", rails_files: %w[lib/**/engine.rb lib/**/railtie.rb lib/generators/**/* lib/tasks/**/*] }
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

DEV_MATERIAL = %r{\A(?:test|spec|dev|doc|docs(?!/[^/]+\.md\z)|oracle|node_modules|tmp|react-[\w-]+|\.github|\.claude|\.ai|bin/ci|Gemfile\.lock)(?:/|\z)}
REQUIRED_METADATA = %w[source_code_uri changelog_uri].freeze
# Stimulus controllers that exist only for the dev kit's parity harness and demo pages.
DEV_CONTROLLER = %r{(?:\A|/)(?:_probe_[^/]*|theme_panel_controller\.js)\z}
GITHUB_URI = %r{\Ahttps://github\.com/[\w.-]+/[\w.-]+/(?:blob|tree)/[\w.-]+/\S+\z}
# A bare repository URI is a valid source_code_uri for a gem that sits at the root of its own repository.
GITHUB_REPO = %r{\Ahttps://github\.com/[\w.-]+/[\w.-]+/?\z}
# A second /tree|blob/<ref>/ after the first, adjacent or not (`#{homepage}/blob/main/...` appended to a tree/ homepage).
DOUBLE_REF = %r{/(?:tree|blob)/[^/]+/(?:.*/)?(?:tree|blob)/}

if spec
  { "name" => spec.name, "version" => spec.version.to_s, "summary" => spec.summary, "description" => spec.description, "authors" => spec.authors,
    "license" => spec.licenses, "homepage" => spec.homepage }.each do |field, value|
    add.call("GEMSPEC_FIELD", specs.first, nil, "#{field} is missing or empty") if value.nil? || (value.respond_to?(:empty?) && value.empty?) || value.to_s == "0"
  end
  add.call("GEMSPEC_FIELD", specs.first, nil, "required_ruby_version is not set (it defaults to >= 0)") if spec.required_ruby_version.to_s == ">= 0"
  REQUIRED_METADATA.each { |m| add.call("GEMSPEC_FIELD", specs.first, nil, "metadata[#{m}] is missing") unless spec.metadata[m] }
  packaged = spec.files.select { |f| f.match?(DEV_MATERIAL) }
  add.call("GEMSPEC_FILES", specs.first, nil, "packages development material: #{packaged.first(6).join(', ')}#{packaged.size > 6 ? ' ...' : ''}") if packaged.any?
  dev_controllers = spec.files.select { |f| f.match?(DEV_CONTROLLER) }
  add.call("GEMSPEC_DEV_MATERIAL", specs.first, nil, "packages dev-only controllers: #{dev_controllers.first(4).join(', ')}#{dev_controllers.size > 4 ? ' ...' : ''}") if dev_controllers.any?
  { "homepage" => spec.homepage }.merge(spec.metadata.select { |key, _| key.end_with?("_uri") }).each do |field, value|
    uri = begin
      URI.parse(value.to_s)
    rescue URI::InvalidURIError
      nil
    end
    well_formed = uri.is_a?(URI::HTTP) && uri.host && !uri.host.empty?
    add.call("GEMSPEC_METADATA", specs.first, nil, "#{field} is not a well-formed http(s) URI: #{value.inspect}") unless well_formed || value.to_s.empty?
    next unless well_formed && uri.host == "github.com" && %w[source_code_uri changelog_uri].include?(field)

    shaped = (value.match?(GITHUB_URI) && !value.match?(DOUBLE_REF)) || (field == "source_code_uri" && value.match?(GITHUB_REPO))
    add.call("GEMSPEC_METADATA", specs.first, nil, "#{field} #{value} does not have the shape https://github.com/<owner>/<repo>/(blob|tree)/<ref>/<path>") unless shaped
  end
end
add.call("GEMSPEC_LICENSE", nil, nil, "no LICENSE / LICENSE.txt / MIT-LICENSE") if Dir[File.join(gem_dir, "{LICENSE,LICENSE.*,MIT-LICENSE,COPYING}")].empty?
add.call("GEM_NO_TESTS", nil, nil, "no test/ or spec/ directory") unless Dir.exist?(File.join(gem_dir, "test")) || Dir.exist?(File.join(gem_dir, "spec"))

# ---- Ruby sources ------------------------------------------------------------------------------------------------
lib_files = Dir[File.join(gem_dir, "{lib,app}/**/*.rb")]
rails_glob = opts[:rails_files].flat_map { |g| Dir[File.join(gem_dir, g)] }.select { |f| File.file?(f) }
code_of = ->(file) { File.readlines(file).each_with_index.map { |l, i| [ i + 1, l.sub(/(?<!\S)#(?![{@$]).*\z/, "") ] } }
sources = lib_files.to_h { |f| [ f, code_of.call(f) ] }
host_path_allowed_files = HOST_PATH_ALLOW_GLOBS.flat_map { |g| Dir[File.join(gem_dir, g)] }
host_path_marked_lines = lambda do |file|
  next [] unless host_path_allowed_files.include?(file)

  File.readlines(file).each_with_index.filter_map { |l, i| i + 1 if l.match?(HOST_PATH_ALLOW_MARKER) }
end
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
  marked = host_path_marked_lines.call(file)
  lines.each do |n, text|
    host_constants.each do |const|
      add.call("GEM_HOST_CONSTANT", file, n, "references #{const}, defined by the host app") if text.match?(/(?<![\w:])#{const}(?:::|\.\w)/)
    end
    if (rel = text[/require_relative\s+["']((?:\.\.\/)+)/, 1])
      depth = File.dirname(file.delete_prefix("#{gem_dir}/")).split("/").reject { |part| part == "." }.size
      add.call("GEM_ESCAPES_ROOT", file, n, "require_relative leaves the gem directory (#{rel.scan('../').size} levels up from depth #{depth})") if rel.scan("../").size > depth
    end
    add.call("GEM_ESCAPES_ROOT", file, n, "hard-coded host path (app/... or Rails.root); only doctor files may allow it, with `# gem_check:allow GEM_ESCAPES_ROOT -- <reason>` on the same line") if text.match?(/["'](?:\.\/)?app\/(?:assets|javascript|views|components)\//) && !rails_glob.include?(file) && !marked.include?(n)
  end
end

# Rails / ActiveSupport use outside the integration layer.
rails_re = /(?<![\w:])(?:Rails|ActionView|ActionController|ActiveRecord|ActionDispatch)\b/
# `defined?(Rails::Engine)` (R2: the engine is loaded only when Rails is there) probes for Rails, it does not depend on it.
rails_guard = /\bdefined\?\(\s*Rails(?:::\w+)*\s*\)/
sources.each do |file, lines|
  next if rails_glob.include?(file)

  lines.each { |n, text| add.call("GEM_RAILS_REFERENCE", file, n, "#{text[rails_re]} used outside the Rails integration files (engine/railtie/generators/tasks)") if text.gsub(rails_guard, "").match?(rails_re) }
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
