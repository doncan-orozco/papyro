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

      def x_handle_without_prefix
        return if x_handle.blank?
        x_handle.delete_prefix("@")
      end

      def x_profile_url
        return if x_handle_without_prefix.blank?
        "https://x.com/#{x_handle_without_prefix}"
      end

      def linkedin_url
        return if linkedin_handle.blank?
        "https://linkedin.com/in/#{linkedin_handle}"
      end
    end
  end
end
