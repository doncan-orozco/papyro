# frozen_string_literal: true

require "yard"

module Phlex
  module Shadcn
    # Builds llms.txt, llms-full.txt and skills/phlex-shadcn/SKILL.md from the YARD registry (constructor kwargs, tags, examples) and the
    # Stimulus controllers (values, events). Nothing is hand-written per component: `rake llms:check` fails when the committed files drift.
    #
    # Scope: components and Stimulus controllers only. Generators and rake tasks are documented by hand elsewhere, so adding one never
    # invalidates these files. Output is deterministic (sorted, no timestamps, no version).
    class Llms
      OUTPUTS = %w[llms.txt llms-full.txt skills/phlex-shadcn/SKILL.md].freeze
      # Top-level classes that are not shadcn components (rendered Lucide glyphs): listed under "Helpers", not counted as components.
      HELPERS = %w[Icon].freeze
      CONTROLLERS_DIR = "app/javascript/controllers/shadcn"
      REPOSITORY = "https://github.com/doncan-orozco/papyro/blob/main/gems/phlex-shadcn"

      Component = Struct.new(:object, :name, :parts, :controllers, keyword_init: true)

      def self.outputs(root) = new(root).outputs

      # @return [Array<String>] the relative paths whose committed content differs from the generated one
      def self.drift(root)
        outputs(root).reject { |path, content| File.exist?(File.join(root, path)) && File.read(File.join(root, path)) == content }.keys
      end

      def self.write(root)
        outputs(root).each do |path, content|
          full = File.join(root, path)
          FileUtils.mkdir_p(File.dirname(full))
          File.write(full, content)
        end
      end

      def initialize(root)
        @root = root
        YARD::Registry.clear
        YARD.parse(Dir[File.join(root, "lib/**/*.rb")].reject { |path| path.end_with?("icons/catalog.rb") })
        @components = collect
      end

      def outputs
        { "llms.txt" => index, "llms-full.txt" => full, "skills/phlex-shadcn/SKILL.md" => skill }
      end

      def component_names = components.map(&:name)

      private

      attr_reader :root

      def components = @components.reject { |c| HELPERS.include?(c.name) }

      def helpers = @components.select { |c| HELPERS.include?(c.name) }

      # ---- collection

      def collect
        tops = YARD::Registry.all(:class).select { |c| c.namespace.path == "Phlex::Shadcn" && base_subclass?(c) && public?(c) }
        tops.sort_by(&:name).map do |object|
          parts = YARD::Registry.all(:class).select { |c| c.namespace == object && base_subclass?(c) && public?(c) }.sort_by(&:name)
          Component.new(object: object, name: object.name.to_s, parts: parts, controllers: controllers_of(object))
        end
      end

      def base_subclass?(object) = object.superclass&.path == "Phlex::Shadcn::Base"

      def public?(object)
        cursor = object
        until cursor.nil? || cursor.root?
          return false if cursor.tag(:api)&.text == "private" || cursor.visibility != :public

          cursor = cursor.parent
        end
        true
      end

      def snake(name) = name.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase

      # Stimulus controllers referenced from the component's own files (lib/phlex/shadcn/<name>.rb and <name>/*.rb) that exist as files.
      def controllers_of(object)
        base = File.join(root, "lib/phlex/shadcn", snake(object.name))
        files = [ "#{base}.rb", *Dir[File.join(base, "**/*.rb")] ].select { |f| File.file?(f) }
        names = files.flat_map { |f| File.read(f).scan(/shadcn--([a-z][a-z-]*)/).flatten }.uniq
        names.select { |n| File.file?(controller_file(n)) }.sort
      end

      def controller_file(name) = File.join(root, CONTROLLERS_DIR, "#{name.tr('-', '_')}_controller.js")

      # ---- YARD readers

      def summary(object) = object.docstring.summary.to_s.gsub(/\s+/, " ").strip

      def constructor(object)
        method = YARD::Registry.at("#{object.path}#initialize")
        return [ "**attrs", [] ] unless method

        params = method.parameters.map do |name, default|
          if default
            name.end_with?(":") ? "#{name} #{default}" : "#{name} = #{default}"
          else
            name
          end
        end
        [ params.join(", "), method.tags(:param) ]
      end

      def example(object)
        tag = object.tags(:example).first
        tag ? tag.text.strip : nil
      end

      # Public enum-like constants (Hash keys or Array elements that are plain identifiers): the accepted values of kwargs such as variant:.
      def enums(object)
        object.constants(inherited: false).filter_map do |constant|
          next unless public?(constant) && constant.name.to_s.match?(/\A[A-Z][A-Z_]*\z/)

          value = Object.const_get(constant.path)
          names = value.is_a?(Hash) ? value.keys : (value.is_a?(Array) ? value : [])
          next unless names.any? && names.all? { |n| (n.is_a?(String) || n.is_a?(Symbol)) && n.to_s.match?(/\A[a-z0-9_-]+\z/i) }

          [ constant.name.to_s, names.map(&:to_s) ]
        end.sort
      end

      # ---- Stimulus readers

      def controller_info(name)
        source = File.read(controller_file(name))
        values = source[/static values = \{(.*?)^  \}/m, 1].to_s.scan(/^    (\w+):/).flatten
        events = (source.scan(/dispatch\(\s*["']([a-z][a-z-]*)["']/).flatten +
                  source.scan(/CustomEvent\(\s*["']shadcn--[a-z-]+:([a-z][a-z-]*)["']/).flatten).uniq.sort
        { values: values.map { |v| v.gsub(/([A-Z])/) { "-#{Regexp.last_match(1).downcase}" } }.sort, events: events }
      end

      # ---- rendering

      def header(title, text) = "# #{title}\n\n> #{text}\n\n"

      SUMMARY = "Phlex components that port shadcn/ui 1:1 (same names, same Tailwind classes, same data-slot markup) with Stimulus behavior " \
                "(`shadcn--*` controllers). Compound components nest their parts (`Dialog::Content`) and also yield a root with one helper per part."

      def index
        out = +header("phlex-shadcn", SUMMARY)
        out << "Generated by `rake llms:generate` from the YARD docs and the Stimulus controllers. Do not edit by hand.\n\n"
        out << "## Docs\n\n"
        out << "- [Full component reference](#{REPOSITORY}/llms-full.txt): every component with constructor keywords, variants, parts, Stimulus controller, events and an example\n"
        out << "- [Agent skill](#{REPOSITORY}/skills/phlex-shadcn/SKILL.md): short usage rules for AI assistants\n"
        out << "- [README](#{REPOSITORY}/README.md): installation and setup\n"
        out << "- [API conventions](#{REPOSITORY}/docs/api-conventions.md): keyword arguments, `as_child`, yielded-root helpers, theming\n\n"
        out << "## Components\n\n"
        components.each { |c| out << "- [#{c.name}](#{REPOSITORY}/llms-full.txt#component-#{snake(c.name).tr('_', '-')}): #{summary(c.object)}\n" }
        out << "\n## Stimulus controllers\n\n"
        controller_names.each { |n| out << "- `shadcn--#{n}`\n" }
        out
      end

      def controller_names
        Dir[File.join(root, CONTROLLERS_DIR, "*_controller.js")].map { |f| File.basename(f, "_controller.js").tr("_", "-") }.sort
      end

      def full
        out = +header("phlex-shadcn: full reference", SUMMARY)
        out << "Generated by `rake llms:generate`. #{components.size} components. Namespace: `Phlex::Shadcn`. Render with `render Phlex::Shadcn::Button.new(...) { ... }`.\n"
        out << "Every component accepts extra keywords as HTML attributes (`class:` is merged with Tailwind conflict resolution, `data:` and `aria:` are deep-merged).\n\n"
        components.each { |c| out << component_section(c) }
        unless helpers.empty?
          out << "## Helpers\n\n"
          helpers.each do |h|
            sig, = constructor(h.object)
            out << "- `Phlex::Shadcn::#{h.name}.new(#{sig})`: #{summary(h.object)}\n"
          end
        end
        out
      end

      def component_section(component)
        object = component.object
        sig, params = constructor(object)
        out = +"<a id=\"component-#{snake(component.name).tr('_', '-')}\"></a>\n## #{component.name}\n\n"
        out << "#{summary(object)}\n\n"
        out << "Constructor: `Phlex::Shadcn::#{component.name}.new(#{sig})`\n\n"
        params.each { |tag| out << "- `#{tag.name}` [#{Array(tag.types).join(', ')}] #{tag.text.to_s.gsub(/\s+/, ' ').strip}\n" }
        out << "\n" unless params.empty?
        enums(object).each { |name, values| out << "- #{name}: #{values.map { |v| "`#{v}`" }.join(', ')}\n" }
        out << "\n" unless enums(object).empty?
        out << parts_block(component) << stimulus_block(component)
        sample = example(object)
        out << "Example:\n\n```ruby\n#{sample}\n```\n\n" if sample
        out
      end

      def parts_block(component)
        return "" if component.parts.empty?

        out = +"Parts (class, yielded-root helper, constructor):\n\n"
        component.parts.each do |part|
          sig, = constructor(part)
          out << "- `#{component.name}::#{part.name}` / `#{snake(part.name)}`: `new(#{sig})`#{(s = summary(part)).empty? ? '' : " #{s}"}\n"
        end
        out << "\n"
      end

      def stimulus_block(component)
        return "" if component.controllers.empty?

        out = +""
        component.controllers.each do |name|
          info = controller_info(name)
          out << "Stimulus: `shadcn--#{name}`"
          out << "; values: #{info[:values].map { |v| "`#{v}`" }.join(', ')}" unless info[:values].empty?
          out << "; events (prefixed `shadcn--#{name}:`): #{info[:events].map { |e| "`#{e}`" }.join(', ')}" unless info[:events].empty?
          out << "\n"
        end
        out << "\n"
      end

      def skill
        <<~MD
          ---
          name: phlex-shadcn
          description: "Use when writing Phlex views with the phlex-shadcn gem (shadcn/ui components for Phlex): component names, constructor keywords, compound parts, Stimulus behavior and theming."
          ---

          # phlex-shadcn

          #{components.size} shadcn/ui components as Phlex classes under `Phlex::Shadcn`. The exact keywords, variants, parts, controllers and events of every component are in [llms-full.txt](../../llms-full.txt) (generated, always current): read the section of the component before using it.

          ## Rules

          1. Render with `render Phlex::Shadcn::Button.new(variant: "outline") { "Save" }`. Unknown variants or sizes raise `ArgumentError`.
          2. Compound components nest parts (`Phlex::Shadcn::Dialog::Content`). The root also yields itself with one helper per part (`dialog.trigger { "Open" }`); both forms render the same markup.
          3. Extra keywords become HTML attributes. `class:` is merged with `tailwind_merge` (yours wins), `data:` and `aria:` are deep-merged. Do not copy shadcn Tailwind classes into your views: they are already applied.
          4. `as_child:` renders the part's props onto another tag or component instead of its default element.
          5. Behavior comes from Stimulus controllers named `shadcn--<component>`. Events are dispatched as `shadcn--<component>:<event>`; values are set with `data-shadcn--<component>-<value>-value`.
          6. Colors come from shadcn-format CSS variables (`--primary`, `--background`, ...): change the theme file, not the components.

          ## Components

          #{components.map { |c| "`#{c.name}`" }.join(', ')}.

          ## Stimulus controllers

          #{controller_names.map { |n| "`shadcn--#{n}`" }.join(', ')}.
        MD
      end
    end
  end
end
