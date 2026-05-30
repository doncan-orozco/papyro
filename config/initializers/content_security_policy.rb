# Be sure to restart your server when you modify this file.
require "uri"

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

public_host = ENV.fetch("APP_HOST", "https://papyro.net")
public_uri = URI.parse(public_host)
public_origin = "#{public_uri.scheme}://#{public_uri.host}"
studio_origin = "#{public_uri.scheme}://studio.#{public_uri.host}"

Rails.application.configure do
	config.content_security_policy do |policy|
		policy.default_src :self, :https
		policy.font_src :self, :https, :data
		policy.img_src :self, :https, :data
		policy.object_src :none
		policy.script_src :self, :https
		policy.style_src :self, :https, :unsafe_inline
		policy.style_src_elem :self, :https, :unsafe_inline
		policy.style_src_attr :self, :https, :unsafe_inline
		policy.connect_src :self,
			:https,
			:wss,
			public_origin,
			studio_origin,
			"http://lvh.me:3030",
			"http://studio.lvh.me:3030",
			"http://localhost:3030",
			"http://localhost:3000"
	end

	# Nonces allow secure inline script/style emission when helpers support it.
	config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
	config.content_security_policy_nonce_directives = %w(script-src)
	config.content_security_policy_nonce_auto = true
end
