# frozen_string_literal: true

class DesignSystemController < ApplicationController
  allow_unauthenticated_access

  def index
    skip_policy_scope
    render Views::DesignSystem::Index.new
  end

  def react
    skip_authorization
    render Views::DesignSystem::React.new
  end

  def compare
    skip_authorization
    render Views::DesignSystem::Compare.new
  end
end
