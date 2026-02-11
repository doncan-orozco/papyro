# Model Examples

**For complete guidelines, see: [ai_agent/VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#models)**

Models are for persistence only - associations only. Code examples below.

## Database Constraints (Migration)

```ruby
# db/migrate/xxx_create_articles.rb
class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title, null: false          # NOT NULL constraint
      t.string :slug, null: false           # NOT NULL constraint
      t.string :status, null: false         # NOT NULL constraint
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index :slug, unique: true           # UNIQUE constraint
      t.check_constraint "status IN ('draft', 'published', 'archived')", name: "valid_status"
    end
  end
end
```

## Model (Persistence Layer)

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :author, class_name: "User"
  has_many :comments, dependent: :destroy

  # Rails 8: Normalize data automatically
  normalizes :title, with: -> { _1.strip }
  normalizes :slug, with: -> { _1.strip.downcase }

  # NO business validations (use Contracts)
  # Optional: Safety-net validations (paranoid mode, apply in all environments)
  validates :title, presence: true
  validates :status, inclusion: { in: %w[draft published archived] }
end
```

## Query Object (Read Queries)

```ruby
# app/queries/article/published_query.rb
module Article
  class PublishedQuery
    def self.call
      ::Article.where(status: "published").order(created_at: :desc)
    end
  end
end
```

## Contract (Business Validation)

```ruby
# app/concepts/article/contract/create.rb
module Article
  module Contract
    class Create < Reform::Form
      property :title
      property :slug
      property :status
      property :author_id

      validation do
        required(:title).filled(:string, max_size?: 255)
        required(:slug).filled(:string, format?: /\A[a-z0-9-]+\z/)
        required(:status).filled(:string, included_in?: %w[draft published])
        required(:author_id).filled(:integer)
      end

      # Complex cross-field validation
      rule(:title, :status) do
        if values[:status] == "published" && values[:title].length < 10
          key(:title).failure("must be at least 10 characters for published articles")
        end
      end
    end
  end
end
```

See [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#models) for complete model guidelines.
