# frozen_string_literal: true

# @label Card  
# @display bg_color "#f8f9fa"
class CardPreview < Lookbook::Preview
  # Basic card with all sections
  # @label Default
  def default
    render CardWithFooterExample.new
  end

  # Card without footer
  # @label Simple
  def simple
    render SimpleCardExample.new
  end

  # Card with just content
  # @label Content Only
  def content_only
    render ContentOnlyCardExample.new
  end
end

# Example component: Card with header, content, and footer
class CardWithFooterExample < Components::Base
  def view_template
    render Components::Ui::Card.new(class: "max-w-md") do
      render Components::Ui::CardHeader.new do
        render Components::Ui::CardTitle.new do
          "Card Title"
        end
        render Components::Ui::CardDescription.new do
          "Card description goes here"
        end
      end

      render Components::Ui::CardContent.new do
        p(class: "text-sm") do
          "This is the main content area of the card."
        end
      end

      render Components::Ui::CardFooter.new do
        render Components::Ui::Button.new(variant: :outline) do
          "Cancel"
        end
        render Components::Ui::Button.new(class: "ml-2") do
          "Submit"
        end
      end
    end
  end
end

# Example component: Simple card without footer
class SimpleCardExample < Components::Base
  def view_template
    render Components::Ui::Card.new(class: "max-w-md") do
      render Components::Ui::CardHeader.new do
        render Components::Ui::CardTitle.new do
          "Simple Card"
        end
        render Components::Ui::CardDescription.new do
          "A card without a footer"
        end
      end

      render Components::Ui::CardContent.new do
        p(class: "text-sm") do
          "This card only has a header and content."
        end
      end
    end
  end
end

# Example component: Card with only content
class ContentOnlyCardExample < Components::Base
  def view_template
    render Components::Ui::Card.new(class: "max-w-md") do
      render Components::Ui::CardContent.new do
        p(class: "text-sm") do
          "This is a card with just content."
        end
      end
    end
  end
end
