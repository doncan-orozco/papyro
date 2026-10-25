# frozen_string_literal: true

# The V2 catalog index (/design-system): one entry per ported component, read from the chadcn gem's packaged catalog
# (`Chadcn::Catalog`), which previews each component's first light default scenario. The host only adds the page anchor.
class Components::Parity::Catalog
  class Entry < SimpleDelegator
    def anchor = "v2-#{component}"
  end

  def self.entries = Chadcn::Catalog.entries.map { |entry| Entry.new(entry) }
end
