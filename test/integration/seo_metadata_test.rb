require "test_helper"

class SeoMetadataTest < ActionDispatch::IntegrationTest
  test "layout renders canonical and hreflang tags" do
    get root_path

    assert_select "link[rel='canonical']", 1
    assert_select "link[rel='alternate'][hreflang='en']", 1
    assert_select "link[rel='alternate'][hreflang='es']", 1
  end

  test "layout renders seo meta tags" do
    get root_path

    assert_select "link[rel='alternate'][hreflang='x-default']", 1
    assert_select "meta[name='description']", 1
    assert_select "meta[property='og:locale']", 1
  end
end
