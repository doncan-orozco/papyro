# frozen_string_literal: true

module Articles
  class EmptyTrashJob < ApplicationJob
    queue_as :maintenance

    def perform
      Article.trashed.where("deleted_at <= ?", 30.days.ago).find_each do |article|
        article.destroy
      end
    end
  end
end
