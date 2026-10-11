# frozen_string_literal: true

# Phlex side of the shadcn port parity harness (development and test only, see config/routes.rb).
# React twin: react-shadcn-catalog/src/parity/Harness.tsx. Contract: .ai/skills/shadcn-port/references/parity-gates.md.
class DesignSystemParityController < ApplicationController
  allow_unauthenticated_access
  before_action { head :not_found unless Rails.env.development? || Rails.env.test? }

  def show
    skip_authorization
    scenario = Components::Parity::Scenario.find(params[:component], params[:scenario])
    tree = Components::Parity::TreeRenderer.new(tree: scenario.fetch("tree"), component: params[:component], dx: params[:dx])
    render Views::DesignSystem::Parity::Show.new(html: view_context.render(tree)), layout: false
  rescue Components::Parity::Scenario::NotFound => e
    render_error(e, :not_found)
  rescue StandardError => e
    Rails.logger.error("[parity] #{e.class}: #{e.message}\n#{e.backtrace.first(8).join("\n")}")
    render_error(e, :internal_server_error)
  end

  def theme_panel
    skip_authorization
    panel = Views::DesignSystem::ThemePanel.new
    render Views::DesignSystem::Parity::Show.new(html: view_context.render(panel)), layout: false
  end

  private

  def render_error(error, status)
    render Views::DesignSystem::Parity::Show.new(error: "#{error.class}: #{error.message}"), layout: false, status: status
  end
end
