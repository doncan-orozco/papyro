class GoldenPublicationsController < ApplicationController
  def create
    authorize article, policy_class: Studio::PublicationPolicy
    result = Golden::Operation::Publish.new.call(model: article, user: Current.user)

    if result.success?
      redirect_to article_path(article), notice: t("golden.publications.create.success"), status: :see_other
    else
      render Views::Golden::Articles::Show.new(article: result.failure[:model]), status: :unprocessable_entity
    end
  end

  private

  def article
    @article ||= Current.user.articles.find_by!(uuid: params[:article_uuid])
  end
end
