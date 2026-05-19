module Users
  module OauthAuthenticatable
    extend ActiveSupport::Concern

    OAUTH_USERNAME_FORMAT = /[^a-z0-9_]/.freeze
    OAUTH_USERNAME_MIN_LENGTH = 3
    OAUTH_USERNAME_MAX_LENGTH = 30

    class_methods do
      def from_omniauth(auth)
        provider = oauth_value(auth, :provider).to_s
        uid = oauth_value(auth, :uid).to_s
        email_address = oauth_value(oauth_value(auth, :info), :email).to_s.strip.downcase
        display_name = oauth_value(oauth_value(auth, :info), :name).to_s.strip

        raise ArgumentError, "OAuth provider is required" if provider.blank?
        raise ArgumentError, "OAuth uid is required" if uid.blank?
        raise ArgumentError, "OAuth email is required" if email_address.blank?

        user = find_or_initialize_by(provider: provider, uid: uid)
        unless user.new_record?
          user.update!(verified_at: Time.current) unless user.verified?
          return user
        end

        base_username = build_oauth_username_base(email_address)
        username = next_available_profile_username(base_username)

        transaction do
          user.email_address = email_address
          user.password = SecureRandom.hex(16)
          user.verified_at = Time.current
          user.save!
          user.create_profile!(
            display_name: display_name.presence || username,
            username: username
          )
        end

        user
      end

      def build_oauth_username_base(email_address)
        local_part = email_address.to_s.split("@").first.to_s.downcase
        sanitized = local_part.gsub(OAUTH_USERNAME_FORMAT, "")
        normalized = sanitized.first(OAUTH_USERNAME_MAX_LENGTH).presence || "usr"

        normalized.ljust(OAUTH_USERNAME_MIN_LENGTH, "0")
      end

      def next_available_profile_username(base_username)
        suffix = 0

        loop do
          suffix_text = suffix.zero? ? "" : suffix.to_s
          max_base_length = OAUTH_USERNAME_MAX_LENGTH - suffix_text.length
          candidate = "#{base_username.first(max_base_length)}#{suffix_text}"

          return candidate unless AuthorProfile.where("lower(username) = ?", candidate.downcase).exists?

          suffix += 1
        end
      end

      def oauth_value(payload, key)
        if payload.respond_to?(:[])
          value = payload[key]
          value = payload[key.to_s] if value.nil?
          return value unless value.nil?
        end

        payload.public_send(key) if payload.respond_to?(key)
      end
    end
  end
end
