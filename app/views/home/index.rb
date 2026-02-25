module Views
  module Home
    class Index < Views::Base
      def view_template
        div(class: "min-h-screen bg-background") do
          # Header/Navigation
          header(class: "sticky top-0 z-50 border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60") do
            div(class: "mx-auto max-w-6xl px-4 h-16 flex items-center justify-between") do
              div(class: "flex items-center gap-2") do
                span(class: "text-2xl font-bold text-primary") { "Papyro" }
              end
              nav(class: "flex gap-6 text-sm") do
                link_to t(".articles", default: "Articles"), admin_articles_path, class: "text-muted-foreground hover:text-foreground transition"
                link_to t(".design_system", default: "Design System"), design_system_path, class: "text-muted-foreground hover:text-foreground transition"
              end
            end
          end

          main(class: "mx-auto max-w-6xl px-4 py-12 sm:py-20") do
            # Hero Section
            div(class: "mx-auto max-w-2xl text-center mb-16") do
              render Components::Ui::Badge.new(variant: :secondary, class: "uppercase tracking-widest mb-4") do
                "Welcome"
              end

              h1(class: "text-4xl sm:text-5xl font-bold tracking-tight text-foreground mb-6") do
                "An elegant platform for articles and content"
              end

              p(class: "text-xl text-muted-foreground mb-8 leading-relaxed") do
                "Build, manage, and publish beautiful content with Papyro. A modern, design-system-driven platform built with Rails, Phlex, and Tailwind CSS."
              end

              div(class: "flex gap-4 justify-center") do
                link_to t(".get_started", default: "Get Started"),
                  admin_articles_path,
                  class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-8 bg-primary text-primary-foreground shadow hover:bg-primary/90"

                link_to t(".learn_more", default: "Learn More"),
                  "#features",
                  class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-8 border border-input bg-background hover:bg-muted"
              end
            end

            # Features Section
            div(id: "features", class: "mt-20 grid grid-cols-1 md:grid-cols-3 gap-6") do
              feature_card(
                "📝",
                t(".feature_content", default: "Content Management"),
                t(".feature_content_desc", default: "Easy-to-use interface for creating and managing articles")
              )
              feature_card(
                "🎨",
                t(".feature_design", default: "Design System"),
                t(".feature_design_desc", default: "Consistent, beautiful UI components based on shadcn/ui")
              )
              feature_card(
                "🌍",
                t(".feature_i18n", default: "Internationalization"),
                t(".feature_i18n_desc", default: "Full support for multiple languages")
              )
            end
          end
        end
      end

      private

      def feature_card(icon, title, description)
        render Components::Ui::Card.new(class: "border border-border/50 hover:border-border transition") do
          render Components::Ui::CardHeader.new do
            p(class: "text-3xl mb-2") { icon }
            render Components::Ui::CardTitle.new { title }
          end
          render Components::Ui::CardContent.new(class: "pt-0") do
            p(class: "text-muted-foreground") { description }
          end
        end
      end
    end
  end
end
