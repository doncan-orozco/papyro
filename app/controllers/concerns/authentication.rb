module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :resume_session, **options
    end
  end

  private

    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      session_record = Current.session || find_session_by_cookie
      Current.session = session_record
      if session_record
        Current.user = session_record.user
        persist_shared_session_cookie(session_record)
      else
        session[:guest_id] ||= SecureRandom.uuid
        Current.user = GuestUser.new
      end
      session_record
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to authentication_redirect_path
    end

    def authentication_redirect_path
      new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_path(locale: I18n.locale)
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        Current.user = user
        persist_shared_session_cookie(session)
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
      Current.user = nil

      cookies.delete(:session_id, domain: Rails.configuration.x.cookie_domain)
    end

    def persist_shared_session_cookie(session)
      cookies.signed.permanent[:session_id] = {
        value: session.id,
        domain: Rails.configuration.x.cookie_domain,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production? # This one is actually fine to keep!
      }
    end
end
