require "test_helper"

class Components::Shared::FlashTest < ActiveSupport::TestCase
  test "mounts one polite Sonner live region as the toaster turbo streams target" do
    toaster = render_flash({}).css("section").sole

    assert_equal "chadcn--sonner", toaster["data-controller"]
    assert_equal "toaster", toaster["id"]
    assert_equal "polite", toaster["aria-live"]
    assert_empty toast_templates(toaster)
  end

  test "keeps the legacy position, duration and localized close label" do
    toaster = I18n.with_locale(:es) { render_flash({}).at_css("section") }

    assert_equal "bottom-right", toaster["data-chadcn--sonner-position-value"]
    assert_equal "4000", toaster["data-chadcn--sonner-duration-value"]
    assert_equal "true", toaster["data-chadcn--sonner-close-button-value"]
    assert_equal I18n.t("app.toasts.close", locale: :es),
      JSON.parse(toaster["data-chadcn--sonner-toast-options-value"])["closeButtonAriaLabel"]
  end

  test "suppressed keeps the toaster mounted but drops the messages" do
    toaster = render_flash({ notice: "Hidden" }, suppressed: true).css("section").sole

    assert_empty toast_templates(toaster)
  end

  test "renders a notice as a success toast with the localized title" do
    toast = toast_templates(render_flash(notice: "Saved successfully")).sole

    assert_equal "success", toast["data-type"]
    assert_equal I18n.t("app.toasts.success"), part(toast, "title")
    assert_equal "Saved successfully", part(toast, "description")
  end

  test "renders an alert as an error toast in Spanish" do
    toast = I18n.with_locale(:es) { toast_templates(render_flash(alert: "Algo falló")).sole }

    assert_equal "error", toast["data-type"]
    assert_equal I18n.t("app.toasts.error", locale: :es), part(toast, "title")
    assert_equal "Algo falló", part(toast, "description")
  end

  test "renders one toast per notice or alert message and skips blank and other keys" do
    toasts = toast_templates(render_flash(notice: [ "One", "" ], alert: [ "Two", nil ], success: "Ignored"))

    assert_equal %w[One Two], toasts.map { |toast| part(toast, "description") }
  end

  private

  def render_flash(flash, **options)
    Nokogiri::HTML5.fragment(ApplicationController.render(Components::Shared::Flash.new(flash: flash, **options), layout: false))
  end

  def part(toast, name)
    toast.at_css("[data-#{name}]")&.text
  end

  def toast_templates(node)
    node.css("template[data-chadcn--sonner-toast]")
  end
end
