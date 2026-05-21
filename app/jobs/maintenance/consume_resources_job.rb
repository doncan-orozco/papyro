# frozen_string_literal: true

class Maintenance::ConsumeResourcesJob < ApplicationJob
  class ConsumeResourcesFailed < StandardError; end

  queue_as :maintenance

  # Limit concurrency to avoid system overload
  limits_concurrency to: 1, key: -> { "maintenance_consume_resources" }

  # Do not retry on operation failure
  discard_on ConsumeResourcesFailed


  before_perform do
    if ENV["APP_ENV"] == "qa"
      Rails.logger.info("Skipped Maintenance::ConsumeResourcesJob because we are in the QA environment.")
      throw(:abort)
    end
  end

  def perform
    result = Maintenance::ConsumeResources.new.call
    return Rails.logger.info("Maintenance::ConsumeResourcesJob completed successfully") if result.success?

    message = Array(result.failure.dig(:errors, :base)).compact.join(", ")
    message = "consume resources failed" if message.blank?
    raise ConsumeResourcesFailed, message
  end
end
