# frozen_string_literal: true

# Characterization of the smoke harness (bin/smoke) and of the CI workflow that runs it. Offline: the clean-app mode is not run here
# (it needs network and a browser), only its inputs are checked.
require "test_helper"
require "yaml"
require "rubygems"
require_relative "runner"

class SmokeRunnerTest < Minitest::Test
  GEM_ROOT = Pathname.new(File.expand_path("../..", __dir__))
  WORKFLOW = GEM_ROOT.join("../../.github/workflows/phlex-shadcn.yml")

  def readme = Smoke::Readme.new(GEM_ROOT.join("README.md"))

  def test_the_readme_install_steps_are_the_ones_the_smoke_replays
    assert_equal [ "bundle install", "bin/rails g phlex:shadcn:install", "bin/rails tailwindcss:build" ], readme.install_commands
    assert_includes readme.gemfile_lines, 'gem "phlex-shadcn"'
    assert_includes readme.gemfile_lines, 'gem "phlex-rails"'
    assert_match(/class Views::Demo::Index < Views::Base/, readme.view_source)
    assert_match(/class DemoController < ApplicationController/, readme.controller_source)
    assert_match(%r{\Arequire "phlex/shadcn"}, readme.without_rails_source)
  end

  def test_the_docs_fences_include_the_readme_and_every_guide
    files = Smoke::Docs.new(GEM_ROOT).fences.map { |fence| fence[:file] }.uniq

    assert_includes files, "README.md"
    Dir[GEM_ROOT.join("docs/*.md").to_s].each { |page| assert_includes files, "docs/#{File.basename(page)}" }
  end

  def test_the_plain_smoke_passes_offline_without_rails
    result = Smoke::Plain.new(GEM_ROOT).call

    assert_predicate result, :success?, result.output
    assert_includes result.output, 'data-slot="dialog-trigger"'
  end

  def test_the_workflow_runs_only_for_the_gem
    workflow = YAML.load_file(WORKFLOW)
    triggers = workflow["on"] || workflow[true]

    %w[push pull_request].each do |event|
      assert_equal [ "gems/phlex-shadcn/**", ".github/workflows/phlex-shadcn.yml" ], triggers.fetch(event).fetch("paths"), event
    end
  end

  def test_the_matrix_covers_what_the_gemspec_claims_and_nothing_else
    spec = Gem::Specification.load(GEM_ROOT.join("phlex-shadcn.gemspec").to_s)
    matrix = YAML.load_file(WORKFLOW).dig("jobs", "gem", "strategy", "matrix")
    phlex = spec.dependencies.find { |dependency| dependency.name == "phlex" }.requirement

    matrix.fetch("ruby").each { |ruby| assert spec.required_ruby_version.satisfied_by?(Gem::Version.new(ruby.to_s)), "ruby #{ruby}" }
    assert_includes matrix.fetch("ruby").map(&:to_s), "3.2", "the lowest Ruby the gemspec allows is tested"
    matrix.fetch("gemfile").each do |gemfile|
      path = GEM_ROOT.join(gemfile)

      assert_predicate path, :file?, gemfile
      pinned = File.read(path)[/gem "phlex", "([^"]+)"/, 1]
      next unless pinned

      assert phlex.satisfied_by?(Gem::Version.new(pinned[/[\d.]+/])), "#{gemfile} pins phlex #{pinned}, outside #{phlex}"
    end
  end
end
