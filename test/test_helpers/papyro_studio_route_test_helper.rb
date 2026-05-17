require "uri"

module PapyroStudioRouteTestHelper
  def studio_articles_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.articles_path(*args, **options))
  end

  def studio_article_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.article_path(*args, **options))
  end

  def edit_studio_article_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.edit_article_path(*args, **options))
  end

  def new_studio_article_publication_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.new_article_publication_path(*args, **options))
  end

  def studio_article_publication_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.article_publication_path(*args, **options))
  end

  def studio_article_translation_publication_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.article_translation_publication_path(*args, **options))
  end

  def studio_article_restoration_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.article_restoration_path(*args, **options))
  end

  def studio_article_trashed_article_path(*args, **options)
    wrap_studio_route_path(PapyroStudio::Engine.routes.url_helpers.article_trashed_article_path(*args, **options))
  end

  private

  def wrap_studio_route_path(path)
    return path unless system_test_context?

    base_url = Capybara.current_session.server.base_url
    base_uri = URI.parse(base_url)

    "http://studio.lvh.me:#{base_uri.port}#{path}"
  end

  def system_test_context?
    defined?(ActionDispatch::SystemTestCase) && is_a?(ActionDispatch::SystemTestCase)
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include PapyroStudioRouteTestHelper
end

ActiveSupport.on_load(:action_dispatch_system_test_case) do
  include PapyroStudioRouteTestHelper
end
