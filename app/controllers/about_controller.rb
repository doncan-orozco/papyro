# frozen_string_literal: true

class AboutController < ApplicationController
  allow_unauthenticated_access

  def index
    skip_policy_scope
    render Views::About::Index.new
  end
end
