# frozen_string_literal: true

module Core
  module Query
    class Application
      def self.pipeline(*steps)
        @pipeline_steps = steps.flatten
      end

      def self.pipeline_steps
        @pipeline_steps ||= []
      end

      def self.base_scope(&block)
        @base_scope_proc = block
      end

      def self.evaluated_base_scope
        raise NotImplementedError, "Define a `base_scope` block in #{name}" unless @base_scope_proc

        @base_scope_proc.call
      end

      def self.call(filters = {}, scope: nil)
        initial_scope = scope || evaluated_base_scope
        new(filters, scope: initial_scope).build_query
      end

      attr_reader :filters, :initial_scope

      def initialize(filters, scope:)
        raw_filters = filters || {}
        normalized_filters = if raw_filters.respond_to?(:to_unsafe_h)
          raw_filters.to_unsafe_h
        elsif raw_filters.respond_to?(:to_h)
          raw_filters.to_h
        else
          raw_filters
        end

        @filters = normalized_filters.with_indifferent_access
        @initial_scope = scope
      end

      def build_query
        self.class.pipeline_steps.reduce(initial_scope) do |current_scope, step|
          send(step, current_scope)
        end
      end
    end
  end
end
