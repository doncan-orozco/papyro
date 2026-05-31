# frozen_string_literal: true

require "uri"

class ActionText::Markdown::UploadsController < ApplicationController
  allow_unauthenticated_access only: :show
  helper_method :public_upload_host_options

  before_action do
    ActiveStorage::Current.url_options = public_upload_host_options
  end

  def create
    @record = GlobalID::Locator.locate_signed params[:record_gid]
    authorize @record, :update?

    result = ActionText::Markdown::Uploads::Operation::Create.new.call(
      record: @record,
      attribute_name: params[:attribute_name],
      file: params[:file]
    )

    if result.success?
      @markdown = result.value![:markdown]
      @upload = result.value![:upload]
      render :create, status: :created, formats: :json
    else
      render json: {
        errors: result.failure[:errors],
        message: result.failure[:message]
      }, status: :unprocessable_entity
    end
  end

  def show
    skip_authorization
    @attachment = ActiveStorage::Attachment.find_by!(slug: attachment_slug_candidates)
    expires_in 1.year, public: true
    redirect_to @attachment.url, allow_other_host: true
  end

  private

  def attachment_slug_candidates
    candidates = [ params[:slug].to_s ]

    if params[:format].present?
      candidates << "#{params[:slug]}.#{params[:format]}"
    end

    candidates.uniq
  end

  def public_upload_host_options
    uri = URI.parse(Rails.configuration.x.public_host.to_s)

    {
      host: uri.host,
      port: uri.port,
      protocol: uri.scheme,
      subdomain: ""
    }
  end
end
