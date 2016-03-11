Apipie.configure do |config|
  config.app_name                = "Caritathelp"
  config.api_base_url            = ""
  config.doc_base_url            = "/doc"
  config.validate                = false
  config.validate_value          = false
  config.validate_presence       = false
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
end
