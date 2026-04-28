class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    skip_policy_scope
    render Views::Home::Index.new
  end
end
