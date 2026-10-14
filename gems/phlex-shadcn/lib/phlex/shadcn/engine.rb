# frozen_string_literal: true

require "rails/engine"

module Phlex
  module Shadcn
    # Rails integration, loaded only when Rails::Engine is defined (see lib/phlex/shadcn.rb); the plain-Phlex path never touches it.
    #
    # A host that installs the gem gets, without copying any file:
    #   - the importmap pins for the Stimulus controllers (`controllers/shadcn/*`), the shared primitives (`shadcn/primitives/*`) and the
    #     vendored floating-ui files, so the host's `eagerLoadControllersFrom("controllers")` registers the `shadcn--*` controllers;
    #   - the gem's JavaScript and vendor directories on the asset load path (and watched by importmap's development cache sweeper);
    #   - the theme tooling (`Phlex::Shadcn::Theme`, rake tasks `phlex_shadcn:theme:*`) pointed at the host's theme directory;
    #   - the Tailwind entry point in app/assets/tailwind/phlex-shadcn/engine.css, bundled by tailwindcss-rails, which
    #     `rails g phlex:shadcn:install` imports together with the `@source` line for the gem's Ruby files.
    #
    # Configuration (config/application.rb):
    #   config.phlex_shadcn.theme_dir = "app/assets/tailwind/theme"   # where theme.css and presets/ live (the default shown)
    class Engine < ::Rails::Engine
      # tailwindcss-rails looks for app/assets/tailwind/<engine_name>/engine.css.
      engine_name "phlex-shadcn"

      config.phlex_shadcn = ActiveSupport::OrderedOptions.new
      config.phlex_shadcn.theme_dir = nil

      JAVASCRIPT_DIRECTORIES = %w[app/javascript vendor/javascript].freeze

      initializer "phlex_shadcn.assets" do |app|
        if app.config.respond_to?(:assets)
          JAVASCRIPT_DIRECTORIES.map { |dir| root.join(dir).to_s }.each do |path|
            app.config.assets.paths << path unless app.config.assets.paths.include?(path)
          end
        end
      end

      initializer "phlex_shadcn.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          app.config.importmap.paths << root.join("config/importmap.rb")
          app.config.importmap.cache_sweepers.concat(JAVASCRIPT_DIRECTORIES.map { |dir| root.join(dir) })
        end
      end

      initializer "phlex_shadcn.theme" do |app|
        Phlex::Shadcn::Theme.dir = (app.config.phlex_shadcn.theme_dir || app.root.join("app/assets/tailwind/theme")).to_s
      end
    end
  end
end
