# frozen_string_literal: true

class BackfillPublishedOnArticleTranslations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    ArticleTranslation.unscoped.in_batches(of: 10_000) do |relation|
      relation.where(published: nil).update_all published: false
      sleep(0.01)
    end
  end

  def down
    # no-op: setting nullable published to nil is not meaningful
  end
end
