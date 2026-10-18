# frozen_string_literal: true

# Reads gems/phlex-shadcn/dev/port/scenarios/<component>.json, the single source of truth shared with the React harness.
class Components::Parity::Scenario
  class NotFound < StandardError; end

  NAME = /\A_?[a-z0-9][a-z0-9-]*\z/
  ID = /\A[\w.-]+\z/
  DIRECTORY = Rails.root.join("gems/phlex-shadcn/dev/port/scenarios")

  def self.find(component, id)
    raise NotFound, "invalid component name #{component.inspect}" unless component.to_s.match?(NAME)
    raise NotFound, "invalid scenario id #{id.inspect}" unless id.to_s.match?(ID)

    file = DIRECTORY.join("#{component}.json")
    raise NotFound, "no scenarios for #{component}" unless file.exist?

    JSON.parse(file.read).fetch("scenarios").find { |s| s["id"] == id } || raise(NotFound, "unknown scenario #{id}")
  end
end
