# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActionView::Base.default_form_builder = PapyroFormBuilder
end
