# frozen_string_literal: true

# Lookbook configuration
# https://lookbook.build/guide/config
if Rails.env.development?
  Lookbook.configure do |config|
    # Paths to search for preview files
    config.preview_paths = [ "#{Rails.root}/test/components/previews" ]

    # Paths to search for component files (Phlex views and ViewComponent)
    config.component_paths = [
      "#{Rails.root}/app/components",
      "#{Rails.root}/app/views"
    ]

    # Project name displayed in the Lookbook UI
    config.project_name = "Papyro Design System"

    # Enable live reload in development
    config.listen = true

    # Sort previews alphabetically
    config.sort_examples = true

    # Enable syntax highlighting in code examples
    config.highlighter = :rouge
  end
end
