# frozen_string_literal: true

require "rails/generators"
require "pathname"

module Phlex
  module Shadcn
    module Generators
      # `rails g phlex:shadcn:install` wires the gem into a host that uses tailwindcss-rails:
      #
      # 1. writes one marker-delimited block into the Tailwind entry file (app/assets/tailwind/application.css) right after
      #    `@import "tailwindcss";`: the `@source` line for the gem's Ruby files (Tailwind 4 only generates the classes it finds in
      #    scanned files, so without it the components render unstyled), the import of the engine bundle and of the theme file;
      # 2. copies the default theme (theme.css and presets/) into the host's theme directory unless they already exist.
      #
      # It is idempotent: a second run rewrites the same block and skips the existing theme files, so nothing changes.
      class InstallGenerator < ::Rails::Generators::Base
        desc "Imports the phlex-shadcn Tailwind assets (with the @source line for the gem) and copies the default theme."

        source_root Phlex::Shadcn.root.join("app/assets/tailwind/phlex-shadcn").to_s

        class_option :css, type: :string, default: "app/assets/tailwind/application.css",
                           desc: "The Tailwind entry file of the app"
        class_option :theme_dir, type: :string, default: "app/assets/tailwind/theme",
                                 desc: "Where theme.css and presets/ are kept (config.phlex_shadcn.theme_dir)"

        BLOCK_START = "/* phlex-shadcn:start (managed by rails g phlex:shadcn:install) */"
        BLOCK_END = "/* phlex-shadcn:end */"
        TAILWIND_IMPORT = /^@import\s+["']tailwindcss["'];?[ \t]*$/

        def check_entry_file
          return if File.file?(destination_path(options[:css]))

          raise Thor::Error, "#{options[:css]} not found: install tailwindcss-rails first (bin/rails tailwindcss:install)"
        end

        def write_css_block
          path = destination_path(options[:css])
          original = File.read(path)
          updated = with_block(original)
          return say_status(:identical, options[:css], :blue) if updated == original

          File.write(path, updated)
          say_status(original.include?(BLOCK_START) ? :update : :insert, options[:css], :green)
        end

        def copy_default_theme
          copy_file "theme.css", File.join(options[:theme_dir], "theme.css"), skip: true
          Dir.children(File.join(self.class.source_root, "presets")).sort.each do |preset|
            copy_file File.join("presets", preset), File.join(options[:theme_dir], "presets", preset), skip: true
          end
        end

        def show_next_steps
          say "\nRun bin/rails tailwindcss:build (it bundles the engine CSS) and restart the server.", :green
        end

        private

        def destination_path(relative) = File.join(destination_root, relative)

        def css_directory = Pathname.new(destination_path(options[:css])).dirname

        def relative_to_css(path) = Pathname.new(path).relative_path_from(css_directory).to_s

        def block
          source = relative_to_css(Phlex::Shadcn.root.join("lib"))
          bundle = relative_to_css(destination_path("app/assets/builds/tailwind/phlex-shadcn"))
          theme = relative_to_css(destination_path(File.join(options[:theme_dir], "theme.css")))
          [ BLOCK_START, %(@source "#{source}";), %(@import "#{bundle}";), %(@import "#{theme.start_with?('.') ? theme : "./#{theme}"}";),
            BLOCK_END ].join("\n")
        end

        def with_block(css)
          return css.sub(/#{Regexp.escape(BLOCK_START)}.*?#{Regexp.escape(BLOCK_END)}/mo) { block } if css.include?(BLOCK_START)
          raise Thor::Error, %(#{options[:css]} does not contain @import "tailwindcss";) unless css.match?(TAILWIND_IMPORT)

          css.sub(TAILWIND_IMPORT) { |import| "#{import}\n#{block}" }
        end
      end
    end
  end
end
