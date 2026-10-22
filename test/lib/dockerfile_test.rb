require "test_helper"

class DockerfileTest < ActiveSupport::TestCase
  test "every path the Dockerfile copies from the build context exists" do
    copies = Rails.root.join("Dockerfile").readlines.grep(/\ACOPY\s/).reject { |line| line.include?("--from=") }
    sources = copies.flat_map { |line| line.split.drop(1).reject { |token| token.start_with?("--") }[0...-1] }
    missing = sources.reject { |source| source == "." || Rails.root.join(source).exist? }

    assert_empty missing, "Dockerfile COPY sources missing from the build context: #{missing.join(', ')}"
  end
end
