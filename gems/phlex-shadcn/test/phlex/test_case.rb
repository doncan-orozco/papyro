# frozen_string_literal: true

require "test_helper"

module Phlex
  module Shadcn
    # Plain Minitest with the small `test "…" do` DSL and `assert_not_*` spellings the component tests are written in.
    class TestCase < Minitest::Test
      def self.test(name, &block)
        raise ArgumentError, "test name cannot be empty" if name.to_s.strip.empty?
        raise ArgumentError, "test #{name.inspect} needs a block" unless block

        method_name = "test_#{name.gsub(/\W+/, "_")}"
        raise ArgumentError, "test #{name.inspect} is defined twice in #{self}" if method_defined?(method_name)

        define_method(method_name, &block)
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
