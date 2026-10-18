# frozen_string_literal: true

require "open3"
require "rbconfig"
require "test_helper"

# The README's non-Rails path: Select::Item must render without Nokogiri (a development dependency only). The subprocess
# loads neither Nokogiri nor Rails, and its HTML must equal the output recorded while the Item still used Nokogiri.
class Phlex::Shadcn::Select::PlainRenderTest < Minitest::Test
  DIR = File.expand_path(__dir__)
  LIB = File.expand_path("../../../../lib", __dir__)

  def test_item_renders_byte_identically_without_nokogiri
    out, err, status = Open3.capture3(RbConfig.ruby, "-I", LIB, File.join(DIR, "plain_render.rb"))

    assert_predicate status, :success?, err
    assert_equal File.read(File.join(DIR, "plain_render.html")), out
  end
end
