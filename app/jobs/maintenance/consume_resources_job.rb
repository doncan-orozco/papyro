# frozen_string_literal: true

class Maintenance::ConsumeResourcesJob < ApplicationJob
  queue_as :maintenance

  # Limit concurrency to avoid system overload
  limits_concurrency to: 1, key: -> { "maintenance_consume_resources" }

  # Do not retry on failure
  discard_on StandardError

  def perform
    # Run the dummy operation
    Maintenance::ConsumeResources.call

    Rails.logger.info "Maintenance::ConsumeResourcesJob completed successfully"
  end
end
