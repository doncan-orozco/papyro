class Views::Golden::Pages::About < Views::Base
  def view_template
    h1 { t("golden.pages.about.title") }
    p { t("golden.pages.about.body") }
  end
end
