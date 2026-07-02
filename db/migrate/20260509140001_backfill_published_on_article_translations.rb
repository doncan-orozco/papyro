# frozen_string_literal: true

class BackfillPublishedOnArticleTranslations < ActiveRecord::Migration[8.1]
  def up
    # This backfill is now a no-op because the `published` boolean column
    # it was backfilling was subsequently removed in
    # 20260511230000_remove_legacy_publication_columns_from_article_translations.rb.
    # Any work done here would be immediately discarded.
  end

  def down
    # no-op: setting nullable published to nil is not meaningful
  end
end
