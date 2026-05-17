class BackfillArticleTranslationsStatus < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Map article publication state to translation status enum
    # status: 0 = draft, 1 = in_review, 2 = published
    ArticleTranslation.unscoped.in_batches(of: 10000) do |relation|
      relation.each do |translation|
        article = translation.article

        if article.status == 1 && translation.published?
          # Article is published AND translation is marked published
          translation.update(status: 2, published_at: article.published_at)
        else
          # All other cases: draft
          translation.update(status: 0, published_at: nil)
        end
      end

      sleep(0.01)
    end

    # Set NOT NULL constraint after backfill
    change_column_null :article_translations, :status, false
  end

  def down
    change_column_null :article_translations, :status, true
    ArticleTranslation.unscoped.update_all(status: nil, published_at: nil)
  end
end
