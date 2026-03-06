# frozen_string_literal: true

class DesignSystemController < ApplicationController
  allow_unauthenticated_access

  def index
    render Views::DesignSystem::Index.new
  end

  def react
    render Views::DesignSystem::React.new
  end

  def compare
    render Views::DesignSystem::Compare.new
  end
end
