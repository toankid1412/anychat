unless Rails.env.development?
  ActionMailer::Base.smtp_settings = {
    user_name:            ENV['MAILGUN_USERNAME'],
    password:             ENV['MAILGUN_PASSWORD'],
    domain:               ENV['ANYCHAT_DOMAIN'],
    address:              ENV['MAILGUN_HOST'],
    port:                 587,
    authentication:       :plain
  }
end