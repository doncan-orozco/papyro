# frozen_string_literal: true

class ActionText::Markdown::UploadsController < ApplicationController
  allow_unauthenticated_access only: :show

  before_action do
    ActiveStorage::Current.url_options = { protocol: request.protocol, host: request.host, port: request.port }
  end

  def create
    @record = GlobalID::Locator.locate_signed params[:record_gid]
    authorize @record, :update?

    @markdown = @record.safe_markdown_attribute params[:attribute_name]
    @markdown.uploads.attach [ params[:file] ]
    @markdown.save!

    @upload = @markdown.uploads.attachments.last

    render :create, status: :created, formats: :json
  end

  def show
    skip_authorization
    @attachment = ActiveStorage::Attachment.find_by! slug: "#{params[:slug]}.#{params[:format]}"
    expires_in 1.year, public: true
    redirect_to @attachment.url, allow_other_host: true
  end
end
