# frozen_string_literal: true

# @label Button
# @display bg_color "#f8f9fa"
class ButtonPreview < Lookbook::Preview
  # Default button variant with primary styling
  # @label Default
  def default
    render Components::Ui::Button.new do
      "Click me"
    end
  end

  # Destructive button
  # @label Destructive
  def destructive
    render Components::Ui::Button.new(variant: :destructive) do
      "Delete"
    end
  end

  # Outline button
  # @label Outline
  def outline
    render Components::Ui::Button.new(variant: :outline) do
      "Outline"
    end
  end

  # Secondary button
  # @label Secondary
  def secondary
    render Components::Ui::Button.new(variant: :secondary) do
      "Secondary"
    end
  end

  # Ghost button
  # @label Ghost
  def ghost
    render Components::Ui::Button.new(variant: :ghost) do
      "Ghost"
    end
  end

  # Link button
  # @label Link
  def link
    render Components::Ui::Button.new(variant: :link) do
      "Link"
    end
  end

  # Extra small button
  # @label Extra Small
  def extra_small
    render Components::Ui::Button.new(size: :xs) do
      "Extra Small"
    end
  end

  # Small button
  # @label Small
  def small
    render Components::Ui::Button.new(size: :sm) do
      "Small"
    end
  end

  # Large button
  # @label Large
  def large
    render Components::Ui::Button.new(size: :lg) do
      "Large"
    end
  end

  # Icon button
  # @label Icon
  def icon
    render Components::Ui::Button.new(size: :icon) do
      "+"
    end
  end

  # Disabled button
  # @label Disabled
  def disabled
    render Components::Ui::Button.new(disabled: true) do
      "Disabled"
    end
  end
end
