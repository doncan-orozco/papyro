# frozen_string_literal: true

class MoveOriginalLocaleToArticles < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :articles, :original_locale, :string unless column_exists?(:articles, :original_locale)

    safety_assured do
      execute <<~SQL.squish
        UPDATE articles
        SET original_locale = (
          SELECT locale
          FROM article_translations
          WHERE article_translations.article_id = articles.id
            AND article_translations.is_original = 1
          LIMIT 1
        )
        WHERE EXISTS (
          SELECT 1
          FROM article_translations
          WHERE article_translations.article_id = articles.id
            AND article_translations.is_original = 1
        )
      SQL
    end

    safety_assured do
      execute <<~SQL.squish
        UPDATE articles
        SET original_locale = COALESCE(original_locale, 'en')
        WHERE original_locale IS NULL
      SQL
    end

    change_column_default :articles, :original_locale, "en"
    change_column_null :articles, :original_locale, false

    safety_assured do
      remove_column :article_translations, :is_original, :boolean if column_exists?(:article_translations, :is_original)
    end
  end

  def down
    add_column :article_translations, :is_original, :boolean, default: false, null: false unless column_exists?(:article_translations, :is_original)

    execute <<~SQL.squish
      UPDATE article_translations
      SET is_original = 1
      WHERE locale = (
        SELECT articles.original_locale
        FROM articles
        WHERE articles.id = article_translations.article_id
      )
    SQL

    remove_column :articles, :original_locale, :string if column_exists?(:articles, :original_locale)
  end
end
