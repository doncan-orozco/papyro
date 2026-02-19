# frozen_string_literal: true

class DesignSystemController < ApplicationController
  allow_unauthenticated_access

  def index
    render Views::DesignSystem::Index.new
  end
end
