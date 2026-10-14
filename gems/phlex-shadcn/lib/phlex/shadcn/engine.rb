# frozen_string_literal: true

require "rails/engine"

module Phlex
  module Shadcn
    # Rails integration, loaded only when Rails::Engine is defined (see lib/phlex/shadcn.rb); the plain-Phlex path never touches it.
    # It is required when the gem loads, so rails/engine has to be loaded before the gem (config/application.rb does that before
    # Bundler.require).
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
    #   config.phlex_shadcn.theme_dir = "app/assets/tailwind/theme"   # where theme.css and presets/ live; relative to the app root
    #
    # @api private
    class Engine < ::Rails::Engine
      # tailwindcss-rails looks for app/assets/tailwind/<engine_name>/engine.css.
      engine_name "phlex-shadcn"

      # Where theme.css and presets/ live in the app (the default of `config.phlex_shadcn.theme_dir`).
      DEFAULT_THEME_DIR = "app/assets/tailwind/theme"
      JAVASCRIPT_DIRECTORIES = %w[app/javascript vendor/javascript].freeze
      private_constant :JAVASCRIPT_DIRECTORIES

      config.phlex_shadcn = ActiveSupport::OrderedOptions.new
      config.phlex_shadcn.theme_dir = nil

      initializer "phlex_shadcn.assets" do |app|
        if app.config.respond_to?(:assets)
          JAVASCRIPT_DIRECTORIES.map { |dir| root.join(dir).to_s }.each do |path|
            app.config.assets.paths << path unless app.config.assets.paths.map(&:to_s).include?(path)
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
        # Pathname#join keeps an absolute value and roots a relative one at the app, whatever the working directory is.
        Phlex::Shadcn::Theme.dir = app.root.join(app.config.phlex_shadcn.theme_dir || DEFAULT_THEME_DIR).to_s
      end
    end
  end
end
