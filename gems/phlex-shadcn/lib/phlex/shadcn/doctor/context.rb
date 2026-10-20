# frozen_string_literal: true

require "pathname"

module Phlex
  module Shadcn
    module Doctor
      # What the checks look at: the app's files and the gem versions in its bundle. Everything is injectable, so the checks are tested
      # against fixture directories and never need Rails.
      #
      # @api private
      class Context
        # The Tailwind entry file `rails g phlex:shadcn:install` edits, relative to the app root.
        DEFAULT_CSS = "app/assets/tailwind/application.css"
        # The supported Phlex range when the gem's own specification is not loaded.
        DEFAULT_PHLEX_REQUIREMENT = "~> 2.3"

        # The block `rails g phlex:shadcn:install` writes, from its start marker to its end marker.
        MANAGED_BLOCK = %r{/\* phlex-shadcn:start.*?phlex-shadcn:end \*/}m

        # @return [Pathname] the app root
        attr_reader :root
        # @return [Pathname, nil] the theme directory (theme.css and presets/), nil when none is configured
        attr_reader :theme_dir
        # @return [Pathname] the gem's root, where the `@source` line has to point
        attr_reader :gem_root
        # @return [Hash{String => Gem::Version}] the gems of the bundle
        attr_reader :gems

        # @param root [String, Pathname] the app root
        # @param theme_dir [String, Pathname, nil] absolute, or relative to the root; nil when the app has none configured
        # @param css [String] the Tailwind entry file, relative to the root
        # @param gems [Hash{String => Gem::Version}, nil] the bundle's gems; the loaded specifications by default
        # @param gem_root [Pathname] the root of the gem
        # @param hide_tailwind_stubs [Boolean] `config.phlex_shadcn.hide_tailwind_stubs`
        # @param phlex_requirement [String, Gem::Requirement, nil] the supported Phlex range; the gem's dependency by default
        def initialize(root:, theme_dir: nil, css: DEFAULT_CSS, gems: nil, gem_root: Shadcn.root, hide_tailwind_stubs: true,
                       phlex_requirement: nil)
          @root = Pathname.new(root)
          @theme_dir = theme_dir && @root.join(theme_dir.to_s)
          @css = css
          @gems = gems || Gem.loaded_specs.transform_values(&:version)
          @gem_root = Pathname.new(gem_root)
          @hide_tailwind_stubs = hide_tailwind_stubs
          @phlex_requirement = phlex_requirement
        end

        # @return [Boolean] `config.phlex_shadcn.hide_tailwind_stubs`
        def hide_tailwind_stubs? = @hide_tailwind_stubs

        # @param name [String] gem name
        # @return [Gem::Version, nil] the version in the bundle, nil when the gem is absent
        def gem_version(name) = gems[name]

        # @return [Gem::Requirement] the Phlex versions the gem supports
        def phlex_requirement
          requirement = @phlex_requirement || Gem.loaded_specs["phlex-shadcn"]&.dependencies&.find { |dep| dep.name == "phlex" }&.requirement
          Gem::Requirement.new(requirement || DEFAULT_PHLEX_REQUIREMENT)
        end

        # @return [Pathname] the Tailwind entry file
        def css_path = root.join(@css)

        # @return [String] the Tailwind entry file as the app writes it in messages
        def css_name = @css

        # @return [String, nil] the Tailwind entry file's text, nil when it is missing
        def css_text = css_path.file? ? css_path.read : nil

        # @return [String, nil] the managed `phlex-shadcn:start` ... `phlex-shadcn:end` block of the entry file, nil when it is absent
        def managed_block = css_text&.[](MANAGED_BLOCK)

        # @param value [String] a path as written in the entry file's `@source` or `@import`
        # @return [Pathname] the file or directory it names, relative to the entry file
        def resolve_from_css(value) = Pathname.new(File.expand_path(value, css_path.dirname))

        # @param relative [String] a path relative to the app root
        # @return [Pathname]
        def path(relative) = root.join(relative)
      end
    end
  end
end
