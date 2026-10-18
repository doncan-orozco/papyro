# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "pathname"
require "tempfile"

module Smoke
  # Executes every ```ruby fence of README.md and docs/*.md in one clean child process (no Rails): a fence that defines the README
  # view is rendered through it, the plain-Ruby fence runs as is, every other fence runs inside a Phlex::HTML page. Fences that are
  # not runnable Ruby (Gemfile lines, Rails configuration, a controller) are skipped by content.
  class Docs
    SKIP = [ /\A# Gemfile/, /ApplicationController/, /config\.phlex_shadcn/, /Phlex::Shadcn\.configure/ ].freeze

    def initialize(gem_root)
      @gem_root = Pathname.new(gem_root)
    end

    # @return [Array<Hash>] `{ file:, index:, code: }` for every runnable Ruby fence
    def fences
      files = [ "README.md", *Dir.children(@gem_root.join("docs")).grep(/\.md\z/).sort.map { |page| "docs/#{page}" } ]
      files.flat_map do |file|
        File.read(@gem_root.join(file)).scan(/```ruby\n(.*?)```/m).flatten.each_with_index.filter_map do |code, index|
          { file: file, index: index, code: code } unless SKIP.any? { |pattern| code.match?(pattern) }
        end
      end
    end

    def call
      Tempfile.create([ "phlex-shadcn-doc-fences", ".json" ]) do |file|
        file.write(JSON.generate(fences))
        file.flush
        output, status = Open3.capture2e(RbConfig.ruby, "-I", @gem_root.join("lib").to_s, "-e", RUNNER, file.path)
        [ status.success?, output ]
      end
    end

    RUNNER = <<~'RUBY'
      require "json"
      require "phlex/shadcn"
      Phlex::Shadcn::Loader.eager_load

      module Views; class Base < Phlex::HTML; end; module Demo; end; end
      Invoice = Struct.new(:number, :amount)
      page_class = Class.new(Phlex::HTML) do
        def invoices = [ Invoice.new("INV001", "$250.00") ]
      end

      failures = 0
      fences = JSON.parse(File.read(ARGV[0]), symbolize_names: true)
      fences.each do |fence|
        label = "#{fence[:file]} fence #{fence[:index]}"
        begin
          html =
            if fence[:code].match?(/^class Views::/)
              TOPLEVEL_BINDING.eval(fence[:code], label)
              Views::Demo::Index.new.call
            elsif fence[:code].start_with?('require "phlex/shadcn"')
              TOPLEVEL_BINDING.eval(fence[:code], label)
            else
              page = Class.new(page_class)
              page.class_eval("def view_template\n#{fence[:code]}\nend", label, 0)
              page.new.call
            end
          raise "rendered nothing" if html.to_s.strip.empty?
          puts "ok   #{label} (#{html.bytesize} bytes)"
        rescue Exception => e # rubocop:disable Lint/RescueException
          failures += 1
          puts "FAIL #{label}: #{e.class}: #{e.message.lines.first&.strip}"
        end
      end
      puts "#{fences.size - failures}/#{fences.size} documentation fences rendered"
      exit(failures.zero? ? 0 : 1)
    RUBY
  end
end
