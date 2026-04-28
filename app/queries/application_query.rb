# frozen_string_literal: true

class ApplicationQuery
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

  def self.call(filters = {}, scope: nil, **kwargs)
    combined = filters.merge(kwargs)
    initial_scope = scope || evaluated_base_scope
    new(combined, scope: initial_scope).build_query
  end

  attr_reader :filters, :initial_scope

  def initialize(filters, scope:)
    @filters = filters || {}
    @initial_scope = scope
  end

  def build_query
    self.class.pipeline_steps.reduce(initial_scope) do |current_scope, step|
      send(step, current_scope)
    end
  end
end
