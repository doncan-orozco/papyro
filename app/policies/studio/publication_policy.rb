# frozen_string_literal: true

module Studio
  # Authorizes publish/unpublish actions within the Studio bounded context.
  # Mirrors Studio::PublicationsController exactly: create? = publish, destroy? = unpublish.
  #
  # Using a dedicated namespaced policy keeps Studio rules isolated from Admin or
  # Moderator contexts that may have different publishing semantics.
  class PublicationPolicy < ApplicationPolicy
    # Maps to Studio::PublicationsController#new (load publish modal)
    def new?
      create?
    end

    # Maps to Studio::PublicationsController#create (publish)
    def create?
      owner? && !record.trashed? && article_ready_to_publish?
    end

    # Maps to Studio::PublicationsController#destroy (unpublish)
    def destroy?
      owner? && !record.trashed?
    end

    private

    def owner?
      user.present? && record.user_id == user.id
    end

    def article_ready_to_publish?
      locales_to_check = ([ record.original_locale ] + I18n.available_locales.map(&:to_s)).uniq

      locales_to_check.any? do |locale|
        Mobility.with_locale(locale) { record.title.to_s.strip.present? }
      end
    end
  end
end
