# frozen_string_literal: true

# Round icon link to an external profile (twitter, github, linkedin), built on
# the chadcn outline icon button. Other platforms get the generic accessible
# name and no icon.
#
# Usage:
#   render Components::Shared::SocialLink.new(platform: "github", url: "https://github.com/papyro")
module Components
  module Shared
    class SocialLink < Components::Base
      PLATFORMS = %w[twitter github linkedin].freeze
      private_constant :PLATFORMS

      def initialize(platform:, url:, **attrs)
        @platform = platform.to_s
        @url = url
        @attrs = attrs
      end

      def view_template
        render Chadcn::Button.new(
          **@attrs.except(:class, :aria),
          variant: "outline",
          size: "icon-lg",
          as_child: :a,
          href: @url,
          target: "_blank",
          rel: "noopener noreferrer",
          aria: @attrs.fetch(:aria, {}).merge(label: aria_label),
          class: cn("rounded-full", @attrs[:class])
        ) do
          render Icon.new(@platform, class: "size-5") if known_platform?
        end
      end

      private

      def known_platform?
        PLATFORMS.include?(@platform)
      end

      def aria_label
        if known_platform?
          t("components.ui.social_link.aria.#{@platform}")
        else
          t("components.ui.social_link.aria.default", platform: @platform.capitalize)
        end
      end
    end
  end
end
