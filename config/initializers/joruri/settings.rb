def load_settings(filename)
  file = Rails.root.join(filename)
  YAML::load(ERB.new(File.read(file)).result)[Rails.env].symbolize_keys if File.exist?(file)
end

Rails.application.config.action_mailer.smtp_settings = load_settings('config/smtp.yml')
Joruri.config.imap_settings = load_settings('config/imap.yml')
Joruri.config.sso_settings = load_settings('config/sso.yml')
