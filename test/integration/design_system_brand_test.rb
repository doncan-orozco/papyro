require "test_helper"

# The chadcn brand on the host's V2 design-system page and the brand copies it uses (the gem's demo keeps its own, in doncan-orozco/chadcn): wordmark,
# tagline and disclaimer in EN and ES, sourced only from docs/features/chadcn-rebrand (BRAND.md), never in previews.
class DesignSystemBrandTest < ActionDispatch::IntegrationTest
  BRAND_DIR = Rails.root.join("docs/features/chadcn-rebrand")
  BRAND_FILES = %w[mascot-light.svg mascot-dark.svg wordmark-light.svg wordmark-dark.svg].freeze
  COPIES = { "host" => Rails.root.join("app/assets/images/brand") }.freeze

  test "the V2 catalog shows the light and dark wordmark, the tagline and the disclaimer in English" do
    get design_system_path(locale: :en)

    assert_response :success
    assert_select "header img[alt='chadcn'][src*='brand/wordmark-light']", 1
    assert_select "header img[alt='chadcn'][src*='brand/wordmark-dark']", 1
    assert_select "header p", text: "chadcn go brrrrrr"
    assert_select "footer", text: /Not affiliated with shadcn\. Built on shadcn\/ui \(MIT\)\./
    assert_select "footer a[href='https://ui.shadcn.com']", text: "shadcn/ui"
    assert_select "title", text: /\Achadcn/
  end

  test "the V2 catalog brand strings are translated to Spanish" do
    get design_system_path(locale: :es)

    assert_response :success
    assert_select "header p", text: "chadcn go brrrrrr"
    assert_select "footer", text: /Sin afiliación con shadcn\. Basado en shadcn\/ui \(MIT\)\./
    assert_select "header img[alt='chadcn']", 2
  end

  %i[en es].each do |locale|
    test "the #{locale} tagline carries no link and the subtitle links shadcn/ui once" do
      get design_system_path(locale: locale)

      assert_select "header p", text: "chadcn go brrrrrr" do
        assert_select "a", false
      end
      assert_select "header p a[href='https://ui.shadcn.com']", text: "shadcn/ui", count: 1
    end
  end

  test "the Spanish page carries the chadcn title" do
    get design_system_path(locale: :es)

    assert_select "title", text: /\ACatálogo chadcn/
  end

  test "the Spanish footer links shadcn/ui once" do
    get design_system_path(locale: :es)

    assert_select "footer a[href='https://ui.shadcn.com']", text: "shadcn/ui", count: 1
  end

  test "the light variant hides in dark mode and the dark variant shows only there" do
    get design_system_path(locale: :en)

    assert_select "header img[src*='wordmark-light'].dark\\:hidden"
    assert_select "header img[src*='wordmark-dark'].hidden.dark\\:block"
  end

  test "component previews never carry the brand" do
    get design_system_path(locale: :en)

    assert_select "section[id^=v2-] img[src*='brand/']", false
  end

  COPIES.each do |surface, dir|
    test "the #{surface} brand assets are verbatim copies of the brand guide originals" do
      BRAND_FILES.each do |name|
        copy = dir.join(name)

        assert_predicate copy, :file?, "missing #{copy.relative_path_from(Rails.root)}"
        assert_equal BRAND_DIR.join(name).binread, copy.binread,
                     "#{copy.relative_path_from(Rails.root)} differs from the BRAND.md original"
      end
    end
  end
end
