# frozen_string_literal: true

module Views
  module Authors
    class Show::IdentityHeader < Views::Base
      include Phlex::Rails::Helpers::ImageTag

      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        section(class: "mb-20 grid grid-cols-1 items-start gap-10 md:grid-cols-3 md:gap-12") do
          div(class: "group w-full md:col-span-1 md:self-start") do
            if @presenter.portrait_attached?
              image_tag(
                @presenter.portrait_url,
                alt: @presenter.display_name,
                class: "block aspect-[4/5] w-full overflow-hidden border border-border/60 object-cover grayscale opacity-90 transition-all duration-700 ease-in-out group-hover:scale-[1.01] group-hover:grayscale-0 group-hover:opacity-100"
              )
            else
              div(class: "relative flex aspect-[4/5] w-full items-center justify-center overflow-hidden border border-border/60 bg-gradient-to-br from-muted/55 via-muted/35 to-muted/70 transition-colors duration-700 group-hover:from-rose-500/10 group-hover:to-rose-500/5 dark:group-hover:from-rose-400/20 dark:group-hover:to-rose-400/10") do
                span(class: "pointer-events-none text-[9rem] font-black uppercase leading-none tracking-tighter text-foreground/10 transition-transform duration-700 ease-in-out group-hover:scale-105") do
                  @presenter.avatar_initial
                end
              end
            end
          end

          div(class: "min-w-0 md:col-span-2 md:self-start") do
            div(class: "flex flex-col gap-5") do
              div(class: "flex flex-col gap-5 md:flex-row md:items-start md:justify-between") do
                div(class: "space-y-2") do
                  p(class: "text-xs font-semibold uppercase tracking-[0.2em] text-foreground/80") { "@#{@presenter.username}" }
                  h1(class: "font-serif text-5xl font-semibold tracking-tight text-foreground sm:text-6xl lg:text-7xl") { @presenter.display_name }
                end

                if @presenter.owner?
                  render Components::Ui::Button.new(
                    as: :a,
                    href: edit_settings_profile_path,
                    variant: :outline,
                    size: :sm,
                    class: "w-fit whitespace-nowrap",
                    data: { turbo_frame: "_top" }
                  ) { t("authors.show.edit_profile") }
                end
              end

              if @presenter.bio.present?
                p(class: "max-w-2xl text-lg leading-relaxed text-foreground/75 line-clamp-4") { @presenter.bio }
              end
            end

            if @presenter.any_meta_or_social?
              render Show::MetaAndSocialLinks.new(presenter: @presenter)
            end
          end
        end
      end
    end
  end
end
