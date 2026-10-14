# frozen_string_literal: true

require "pathname"
require "phlex"
require "tailwind_merge"
require "zeitwerk"

module Phlex
  # shadcn/ui components for Phlex.
  module Shadcn
    ROOT = Pathname.new(File.expand_path("../..", __dir__)).freeze

    # The gem's root directory (where `lib`, `app` and `vendor` live), e.g. for a Tailwind `@source` line.
    def self.root = ROOT

    Loader = Zeitwerk::Loader.for_gem_extension(Phlex)
    # The engine is required explicitly below, only inside an app, and is never autoloaded or eager loaded.
    Loader.ignore(File.join(__dir__, "shadcn/engine.rb"))
    Loader.setup
  end
end

require "phlex/shadcn/engine" if defined?(Rails::Engine)
