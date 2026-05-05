# frozen_string_literal: true

module Settings
  class BaseController < ApplicationController
    before_action :authorize_current_user

    # Settings routes are non-localized; suppress locale from default_url_options
    def default_url_options
      {}
    end

    private

    def authorize_current_user
      authorize Current.user
    end
  end
end
