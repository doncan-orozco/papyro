# frozen_string_literal: true

module Authors
  module Presenter
    class Default < Core::Presenter::Base
      def any_meta_or_social?
        location.present? || website_url.present? || x_handle.present? || linkedin_handle.present?
      end

      def owner?
        @current_user&.registered? && @current_user.id == @author.id
      end

      def self.wrap(collection, current_user: Current.user)
        collection.map { |profile| new(profile, author: profile.user, current_user: current_user) }
      end

      def initialize(profile, author:, current_user: Current.user)
        super(profile)
        @author = author
        @current_user = current_user
      end

      def display_name
        super
      end

      def avatar_initial
        display_name.first.to_s.upcase
      end

      def portrait_attached?
        __getobj__.portrait.attached?
      end

      def portrait_url
        return unless portrait_attached?

        helpers.rails_blob_path(__getobj__.portrait, only_path: true)
      end

      def x_handle_without_prefix
        return if x_handle.blank?
        x_handle.delete_prefix("@")
      end

      def x_profile_url
        return if x_handle_without_prefix.blank?
        "https://x.com/#{x_handle_without_prefix}"
      end

      def website_display_value
        return if website_url.blank?

        parsed_host = URI.parse(website_url).host
        return parsed_host.sub(/\Awww\./, "") if parsed_host.present?

        fallback_website_value(website_url)
      rescue URI::InvalidURIError
        fallback_website_value(website_url)
      end

      def linkedin_url
        return if linkedin_handle.blank?

        "https://linkedin.com/in/#{linkedin_handle}"
      end

      def linkedin_display_value
        return if linkedin_handle.blank?

        normalized = linkedin_handle.to_s.strip.delete_prefix("@").delete_prefix("in/")
        return if normalized.blank?

        "in/#{normalized}"
      end

      private

      def fallback_website_value(url)
        stripped = url.to_s.strip
          .sub(%r{\Ahttps?://}i, "")
          .sub(/\Awww\./i, "")
          .split("/")
          .first

        stripped.presence
      end
    end
  end
end
