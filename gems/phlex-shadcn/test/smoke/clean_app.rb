# frozen_string_literal: true

require "fileutils"
require "net/http"
require "pathname"
require "socket"
require "tmpdir"
require_relative "readme"

module Smoke
  # Clean-app smoke (ruby-gem-conventions R10, R14): `rails new`, then the README's Rails quick start replayed verbatim (Gemfile
  # lines, `bundle install`, `bin/rails g phlex:shadcn:install`, `bin/rails tailwindcss:build`, the Views::Demo::Index view and its
  # controller), a running server answering with the Button and the Dialog, the built CSS carrying the gem's classes, and one browser
  # scenario (docs/shadcn-port/scenarios/dialog.json `open__via-trigger-click`, then Escape) driven by Playwright.
  #
  # Needs network (rails new, bundle install), a `rails` executable (SMOKE_RAILS) and node with Playwright (PHLEX_SHADCN_PLAYWRIGHT,
  # or the monorepo's react-shadcn-catalog/node_modules). Never run by `rake test`.
  class CleanApp
    RAILS_NEW_OPTIONS = %w[
      --css tailwind --javascript importmap --skip-git --skip-docker --skip-kamal --skip-ci --skip-solid --skip-active-record
      --skip-active-storage --skip-active-job --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-action-cable
      --skip-jbuilder --skip-test --skip-system-test --skip-rubocop --skip-brakeman --skip-bundler-audit --skip-thruster
      --skip-dev-gems --skip-bootsnap
    ].freeze
    MARKUP = [ 'data-slot="button"', 'data-variant="outline"', 'data-controller="shadcn--dialog"', 'data-slot="dialog-trigger"',
               'data-slot="dialog-content"', '"controllers/shadcn/dialog_controller"' ].freeze
    # Utilities only the gem's Ruby files use: present in the app's build only if the generator's @source line works.
    BUILT_CSS_MARKERS = [ 'ring-\\[3px\\]', "--primary", 'translate-x-\\[-50\\%\\]', "var(--primary)", "animate-in" ].freeze

    def initialize(gem_root, app_dir: ENV.fetch("SMOKE_APP_DIR", nil), keep: ENV["SMOKE_KEEP"] == "1")
      @gem_root = Pathname.new(gem_root)
      @readme = Readme.new(@gem_root.join("README.md"))
      @app_dir = Pathname.new(app_dir || Dir.mktmpdir("phlex-shadcn-smoke-app-")).expand_path
      @keep = keep || !app_dir.nil?
    end

    def call
      create_app
      follow_the_readme
      serve do |port|
        check_http(port)
        browser_scenario(port)
      end
    ensure
      FileUtils.rm_rf(@app_dir) unless @keep
    end

    private

    def say(message) = puts("smoke --app: #{message}")

    def create_app
      FileUtils.rm_rf(@app_dir)
      FileUtils.mkdir_p(@app_dir.dirname)
      say "rails new #{@app_dir}"
      run(ENV.fetch("SMOKE_RAILS", "rails"), "new", @app_dir.to_s, *RAILS_NEW_OPTIONS, chdir: @app_dir.dirname)
      raise "rails new did not install tailwindcss-rails" unless @app_dir.join("app/assets/tailwind/application.css").file?
    end

    # The Gemfile lines of the README, with the gem taken from this checkout until it is released; then every README command.
    def follow_the_readme
      gemfile = @app_dir.join("Gemfile")
      lines = @readme.gemfile_lines.map { |line| line == 'gem "phlex-shadcn"' ? %(gem "phlex-shadcn", path: #{@gem_root.to_s.inspect}) : line }
      File.write(gemfile, "#{File.read(gemfile).chomp}\n\n# From README.md\n#{lines.join("\n")}\n")
      @readme.install_commands.each do |command|
        say command
        run(*command.split, chdir: @app_dir)
        run("bin/rails", "g", "phlex:install", chdir: @app_dir) if command == "bundle install" # phlex-rails: Views::Base, as the README says
      end
      write(@app_dir.join("app/views/demo/index.rb"), @readme.view_source)
      write(@app_dir.join("app/controllers/demo_controller.rb"), @readme.controller_source)
      routes = @app_dir.join("config/routes.rb")
      File.write(routes, File.read(routes).sub(/^end\s*\z/, "  get \"/demo\", to: \"demo#index\"\nend\n"))
    end

    def serve
      port = free_port
      log = @app_dir.join("log/smoke-server.log")
      FileUtils.mkdir_p(log.dirname)
      FileUtils.rm_f(@app_dir.join("tmp/pids/server.pid")) # a leftover pid file makes `rails server` refuse to start
      say "bin/rails server on port #{port}"
      pid = unbundled do
        Process.spawn({ "RAILS_ENV" => "development" }, "bin/rails", "server", "-p", port.to_s, "-b", "127.0.0.1",
                      chdir: @app_dir.to_s, out: log.to_s, err: log.to_s)
      end
      wait_for_server(port, log)
      yield port
    ensure
      if pid
        Process.kill("TERM", pid)
        Process.wait(pid)
      end
    end

    def check_http(port)
      body = get(port).body
      missing = MARKUP.reject { |marker| body.include?(marker) }
      raise "GET /demo lacks #{missing.join(', ')}:\n#{body}" if missing.any?

      css = File.read(@app_dir.join("app/assets/builds/tailwind.css"))
      missing_css = BUILT_CSS_MARKERS.reject { |marker| css.include?(marker) }
      raise "the Tailwind build lacks #{missing_css.join(', ')}: the @source line did not reach the gem" if missing_css.any?

      say "GET /demo renders the Button and the Dialog; the Tailwind build contains the gem's classes"
    end

    def browser_scenario(port)
      say "browser scenario open__via-trigger-click + Escape"
      run("node", @gem_root.join("test/smoke/app/dialog_scenario.mjs").to_s, "http://127.0.0.1:#{port}/demo", chdir: @gem_root)
    end

    def get(port)
      response = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/demo"))
      raise "GET /demo answered #{response.code}:\n#{response.body}" unless response.code == "200"

      response
    end

    def wait_for_server(port, log)
      60.times do
        TCPSocket.new("127.0.0.1", port).close
        return
      rescue Errno::ECONNREFUSED
        sleep 0.5
      end
      raise "the server did not start:\n#{File.read(log)}"
    end

    def free_port
      server = TCPServer.new("127.0.0.1", 0)
      server.addr[1]
    ensure
      server&.close
    end

    def write(path, source)
      FileUtils.mkdir_p(path.dirname)
      File.write(path, source)
    end

    # Commands of the generated app run outside this process' bundle (its own Gemfile, its own gems).
    def run(*command, chdir:)
      success = unbundled { system(*command, chdir: chdir.to_s) }
      raise "command failed (#{command.join(' ')}) in #{chdir}" unless success
    end

    def unbundled(&)
      defined?(Bundler) ? Bundler.with_unbundled_env(&) : yield
    end
  end
end
