# frozen_string_literal: true

require "phlex/test_case"
require "tmpdir"
require "stringio"
require "rake"

# Theme.import against a stand-in for the network: tests have no internet, so Net::HTTP.start is replaced by a scripted server.
class Phlex::Shadcn::ThemeImportTest < Phlex::Shadcn::TestCase
  Theme = Phlex::Shadcn::Theme
  ASSETS = Phlex::Shadcn.root.join("app/assets/tailwind/phlex-shadcn")
  RAKE_FILE = Phlex::Shadcn.root.join("lib/tasks/phlex_shadcn.rake").to_s
  VALID = ASSETS.join("presets/slate.css").read

  # Scripted answers by URL; records every start call. A String is a 200 body, a Class raises, a Hash is a status (+ location/chunks).
  class FakeNet
    attr_reader :requests, :options

    def initialize(routes)
      @routes = routes
      @requests = []
    end

    def start(host, port, **options)
      @options = options
      yield Http.new(self, host, port)
    end

    def answer(url)
      @requests << url
      @routes.fetch(url) { raise "unscripted request #{url}" }
    end

    Http = Struct.new(:net, :host, :port) do
      def request(request)
        response = Response.new(net.answer("https://#{host}#{request.path}"))
        yield response
        response
      end
    end

    Response = Struct.new(:script) do
      def code = script.is_a?(Hash) ? script.fetch(:status).to_s : "200"

      def [](name) = name == "location" && script.is_a?(Hash) ? script[:location] : nil

      def read_body(&block)
        chunks = script.is_a?(Hash) ? script.fetch(:chunks, []) : [ script ]
        chunks.each(&block)
      end
    end
  end

  def setup
    @original_dir = Phlex::Shadcn.config.theme_dir
    @theme_dir = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@theme_dir, "presets"))
    FileUtils.cp(ASSETS.join("theme.css"), File.join(@theme_dir, "theme.css"))
    Phlex::Shadcn.configure { |config| config.theme_dir = @theme_dir }
  end

  def teardown
    Phlex::Shadcn.configure { |config| config.theme_dir = @original_dir }
    FileUtils.remove_entry(@theme_dir)
  end

  def with_network(routes)
    net = FakeNet.new(routes)
    original = Net::HTTP.method(:start)
    Net::HTTP.define_singleton_method(:start) { |*args, **kwargs, &block| net.start(*args, **kwargs, &block) }
    yield net
  ensure
    Net::HTTP.define_singleton_method(:start, original)
  end

  def theme_css = File.read(Theme.theme_file)

  def assert_import_fails(source, message, input: nil)
    before = theme_css
    error = assert_raises(Theme::Error) { Theme.import(source, input: input || StringIO.new("")) }

    assert_match(message, error.message)
    assert_equal before, theme_css, "a failed import must leave theme.css untouched"
  end

  test "an https URL is fetched with timeouts and written with its source label" do
    with_network("https://example.com/t.css" => VALID) do |net|
      Theme.import("https://example.com/t.css")

      assert_equal({ use_ssl: true, open_timeout: Theme::IMPORT_OPEN_TIMEOUT, read_timeout: Theme::IMPORT_READ_TIMEOUT }, net.options)
    end

    assert_includes theme_css, "source: imported https://example.com/t.css"
    assert_empty Theme.check[:errors]
  end

  test "an http URL is rejected without touching the network" do
    with_network({}) do |net|
      assert_import_fails("http://example.com/t.css", /only https/)
      assert_empty net.requests
    end
  end

  test "other schemes and malformed URLs are rejected" do
    assert_import_fails("ftp://example.com/t.css", /only https/)
    assert_import_fails("https://exa mple.com/t.css", /not a valid URL/)
  end

  test "a connection timeout, a refused connection and a TLS error become Theme::Error" do
    [ Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError, OpenSSL::SSL::SSLError ].each do |failure|
      net = Object.new
      net.define_singleton_method(:start) { |*, **, &_| raise failure, "boom" }
      original = Net::HTTP.method(:start)
      Net::HTTP.define_singleton_method(:start) { |*args, **kwargs, &block| net.start(*args, **kwargs, &block) }
      begin
        error = assert_raises(Theme::Error) { Theme.import("https://example.com/t.css") }

        assert_match(%r{cannot fetch https://example.com/t.css}, error.message, failure.name)
      ensure
        Net::HTTP.define_singleton_method(:start, original)
      end
    end
  end

  test "a non-200 status is reported" do
    with_network("https://example.com/t.css" => { status: 404 }) do
      assert_import_fails("https://example.com/t.css", /HTTP 404/)
    end
  end

  test "redirects are followed to an https URL, up to the limit" do
    routes = {
      "https://example.com/a.css" => { status: 302, location: "/b.css" },
      "https://example.com/b.css" => { status: 301, location: "https://cdn.example.com/c.css" },
      "https://cdn.example.com/c.css" => VALID
    }
    with_network(routes) { Theme.import("https://example.com/a.css") }

    assert_empty Theme.check[:errors]
  end

  test "a redirect loop stops at the limit" do
    with_network("https://example.com/a.css" => { status: 302, location: "/a.css" }) do |net|
      assert_import_fails("https://example.com/a.css", /redirected more than #{Theme::IMPORT_MAX_REDIRECTS} times/o)
      assert_equal Theme::IMPORT_MAX_REDIRECTS + 1, net.requests.size
    end
  end

  test "a redirect to http is rejected and a redirect without Location is reported" do
    with_network("https://example.com/a.css" => { status: 302, location: "http://example.com/b.css" }) do
      assert_import_fails("https://example.com/a.css", /only https/)
    end
    with_network("https://example.com/a.css" => { status: 302 }) do
      assert_import_fails("https://example.com/a.css", /without a Location/)
    end
  end

  test "a body over the size cap is refused while it streams" do
    chunk = "a" * 64 * 1024
    chunks = Array.new((Theme::IMPORT_MAX_BYTES / chunk.bytesize) + 1) { chunk }

    with_network("https://example.com/big.css" => { status: 200, chunks: chunks }) do
      assert_import_fails("https://example.com/big.css", /larger than 256 KiB/)
    end
  end

  test "a body that is not UTF-8 is refused" do
    with_network("https://example.com/t.css" => "\xFF\xFE:root { }".b) do
      assert_import_fails("https://example.com/t.css", /not valid UTF-8/)
    end
  end

  test "values that could break theme.css are rejected and leave the file untouched" do
    [ "oklch(1 0 0) */ body {", "oklch(1 0 0) /* x", "url(https://evil.example/x.png)", "red } body { display: none" ].each do |value|
      palette = Theme.parse(VALID)
      palette.root["primary"] = value

      errors = Theme.validate(palette)[:errors]

      assert_predicate errors.grep(/--primary contains text/), :any?, "#{value} should be refused"
    end
  end

  test "a value that opens a block is refused as unbalanced braces" do
    css = VALID.sub(/--primary:\s*[^;]+;/, "--primary: oklch(1 0 0) */ body { display: none; /*;")
    before = theme_css
    error = assert_raises(Theme::Error) { Theme.import("-", input: StringIO.new(css)) }

    assert_match(/unterminated :root block/, error.message)
    assert_equal before, theme_css
  end

  test "a closing comment in a value is an error naming the variable" do
    css = VALID.sub(/--primary:\s*[^;]+;/, "--primary: oklch(1 0 0) */ body;")
    error = assert_raises(Theme::Error) { Theme.import("-", input: StringIO.new(css)) }

    assert_match(/--primary contains text that could break theme.css/, error.message)
  end

  test "the source label cannot close the comment it is written into" do
    with_network("https://example.com/t.css?a=*/b" => VALID) { Theme.import("https://example.com/t.css?a=*/b") }

    label = theme_css[%r{/\* source: (.*?) \*/\n:root}m, 1]

    refute_includes label, "*/"
    assert_includes label, "https://example.com/t.css?a=* /b"
    assert_equal "a b c", Theme.send(:comment_text, "a\n b\r\n c")
    assert_empty Theme.check[:errors]
  end

  test "a missing file is a Theme::Error" do
    assert_import_fails(File.join(@theme_dir, "nope.css"), /cannot read .*nope\.css/)
  end

  test "the rake tasks print the message and exit non-zero without a backtrace" do
    Rake::Task.clear
    Rake::Task.define_task(:environment)
    load RAKE_FILE
    http = Net::HTTP.method(:start)
    Net::HTTP.define_singleton_method(:start) { |*, **, &_| raise Net::OpenTimeout, "execution expired" }
    stderr = StringIO.new
    original = $stderr
    $stderr = stderr
    error = assert_raises(SystemExit) { Rake::Task["phlex_shadcn:theme:import"].invoke("https://example.com/t.css") }

    refute_equal 0, error.status
    assert_match(%r{cannot fetch https://example.com/t.css}, error.message)
    refute_match(/\.rb:\d+/, error.message + stderr.string)

    Rake::Task["phlex_shadcn:theme:import"].reenable
    error = assert_raises(SystemExit) { Rake::Task["phlex_shadcn:theme:import"].invoke("http://example.com/t.css") }

    assert_match(/only https/, error.message)
    refute_match(/\.rb:\d+/, stderr.string)
  ensure
    $stderr = original if original
    Net::HTTP.define_singleton_method(:start, http) if http
    Rake::Task.clear
  end
end
