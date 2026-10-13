# frozen_string_literal: true

# Temporary: serves the phlex-shadcn gem's JavaScript (Stimulus controllers, primitives, vendored floating-ui) through the
# host asset pipeline until the gem ships its own Rails engine. Removed by the host-cutover item.
app = Rails.application
gem_javascript_dirs = %w[app/javascript vendor/javascript].map { |dir| Rails.root.join("gems/phlex-shadcn", dir) }

app.config.assets.paths.push(*gem_javascript_dirs.map(&:to_s))

# Development and test: importmap-rails builds its cache sweeper from this list after the app initializers have run, so adding the
# gem directories makes an edited gem module get a fresh digest in the importmap instead of a 404.
app.config.importmap.cache_sweepers.push(*gem_javascript_dirs)
