# frozen_string_literal: true

require "test_helper"

module Phlex
  module Shadcn
    # Plain Minitest with the small `test "…" do` DSL and `assert_not_*` spellings the component tests are written in.
    class TestCase < Minitest::Test
      def self.test(name, &block)
        define_method("test_#{name.gsub(/\W+/, "_")}", &block)
      end

      def assert_not(*args, **kwargs) = refute(*args, **kwargs)
      def assert_not_includes(*args) = refute_includes(*args)
      def assert_not_nil(*args) = refute_nil(*args)
      def assert_not_equal(*args) = refute_equal(*args)
      def assert_not_predicate(*args) = refute_predicate(*args)
      def assert_not_empty(*args) = refute_empty(*args)
      def assert_not_match(*args) = refute_match(*args)
    end
  end
end
