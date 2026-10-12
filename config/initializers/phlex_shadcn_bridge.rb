# frozen_string_literal: true

# Temporary: serves the phlex-shadcn gem's JavaScript (Stimulus controllers, primitives, vendored floating-ui) through the
# host asset pipeline until the gem ships its own Rails engine. Removed by the host-cutover item.
gem_root = Rails.root.join("gems/phlex-shadcn")
Rails.application.config.assets.paths << gem_root.join("app/javascript").to_s << gem_root.join("vendor/javascript").to_s
