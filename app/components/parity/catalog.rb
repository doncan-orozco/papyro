# frozen_string_literal: true

# The V2 catalog index (/design-system/v2), generated from the scenario files so a demo can never drift from the ported
# component: one entry per `dev/port/scenarios/<component>.json` of the gem whose V2 class exists, previewing its first
# plain (light) default scenario. Harness-only nodes of a scenario (`data-testid` outside/next/neutral probes) are pruned.
# Dev-kit coupling: the gem's dev/ is not packaged, so this works with the path gem only.
require Chadcn.root.join("dev/parity/lib/shadcn_parity").to_s

class Components::Parity::Catalog
  Entry = Struct.new(:component, :title, :scenario_id, :scenario_count, :tree, keyword_init: true) do
    def anchor = "v2-#{component}"
  end

  PROBES = %w[outside next neutral].freeze

  def self.entries(directory: ShadcnParity::Scenario::DIRECTORY)
    Dir[directory.join("*.json").to_s].filter_map do |file|
      component = File.basename(file, ".json")
      next if component.start_with?("_") || !Chadcn.const_defined?(component.tr("-", "_").camelize, false)

      build(component, JSON.parse(File.read(file)).fetch("scenarios", []))
    end.sort_by(&:component)
  end

  def self.build(component, scenarios)
    preview = scenarios.find { |s| s["id"].start_with?("default") && !s["dark"] } || scenarios.find { |s| !s["dark"] }
    return unless preview

    Entry.new(component: component, title: component.tr("-", " ").capitalize, scenario_id: preview["id"],
              scenario_count: scenarios.size, tree: prune(preview.fetch("tree")))
  end

  def self.prune(node)
    return node unless node.is_a?(Hash)

    children = Array(node["children"]).reject { |child| child.is_a?(Hash) && PROBES.include?(child.dig("props", "data-testid")) }
    node.merge("children" => children.map { |child| prune(child) })
  end
end
