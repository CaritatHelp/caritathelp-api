Devise.setup do |config|
  # The e-mail address that mail will appear to be sent from
  # If absent, mail is sent from "please-change-me-at-config-initializers-devise@example.com"
  config.mailer_sender = "rbnvsr@gmail.com"

  # If using rails-api, you may want to tell devise to not use ActionDispatch::Flash
  # middleware b/c rails-api does not include it.
  # See: http://stackoverflow.com/q/19600905/806956
  config.navigational_formats = [:json]

  config.secret_key = '3f3222291dcc08749700bc63b4b2c3d653275addda07c37a61a89ba2fb010cffacb77b1342356b06b3a4c0a2c2134badf37dc0d49e2fa3abb982736e43bbd5c9'
end
