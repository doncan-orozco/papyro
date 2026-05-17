# frozen_string_literal: true

class ActionText::Markdown::UploadsController < ApplicationController
  allow_unauthenticated_access only: :show

  before_action do
    ActiveStorage::Current.url_options = { protocol: request.protocol, host: request.host, port: request.port }
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
    @attachment = ActiveStorage::Attachment.find_by! slug: "#{params[:slug]}.#{params[:format]}"
    expires_in 1.year, public: true
    redirect_to @attachment.url, allow_other_host: true
  end
end
