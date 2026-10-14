# frozen_string_literal: true

# Boots a minimal Rails application in this process (no dummy app, no database) with the same asset gems a host uses, so the
# engine's initializers run for real. Rails must be required before the gem so that `defined?(Rails::Engine)` is true when
# lib/phlex/shadcn.rb loads the engine, exactly as in a host (config/application.rb requires rails before Bundler.require).
ENV["RAILS_ENV"] = "test"

require "rake"
require "rails"
require "propshaft"
require "importmap-rails"
require "tailwindcss-rails"
require "tmpdir"
require "logger"

require_relative "../test_helper"

module EngineTest
  # The directory the application pretends to be (its root), and the theme directory configured through config.phlex_shadcn.
  ROOT = Pathname.new(Dir.mktmpdir("phlex-shadcn-engine-test"))
  THEME_DIR = ROOT.join("custom/theme")

  class Application < Rails::Application
    config.root = ROOT
    config.eager_load = false
    config.logger = Logger.new(IO::NULL)
    config.secret_key_base = "test"
    config.phlex_shadcn.theme_dir = THEME_DIR.to_s
  end

  at_exit { FileUtils.remove_entry(ROOT) if ROOT.exist? }
end

EngineTest::Application.initialize! unless EngineTest::Application.initialized?
