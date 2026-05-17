# frozen_string_literal: true

namespace :articles do
  desc "Fix published articles by marking original locale translations as published"
  task fix_original_locale_translations: :environment do
    Article.status_published.find_each do |article|
      original_translation = article.article_translations.find_by(locale: article.original_locale)
      if original_translation&.update(status: :published, published_at: article.published_at || Time.current)
        puts "✓ Fixed #{article.uuid}: marked #{article.original_locale} translation as published"
      end
    end
    puts "\nDone!"
  end
end
