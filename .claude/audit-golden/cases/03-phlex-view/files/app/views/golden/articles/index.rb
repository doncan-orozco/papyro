class Views::Golden::Articles::Index < Views::Base
  def view_template
    articles = Article.where(status: :published).order(:created_at)

    h1 { "Latest articles" }

    articles.each do |article|
      div(class: article.trashed? ? "text-red-500" : "text-green-600") do
        a(href: "/articles/#{article.slug}") { t(".read_more") }
      end
    end

    p { "Viewed by #{Current.user.name}" }
  end
end
