# frozen_string_literal: true

Zee.app.config :development do
  Mail.defaults { delivery_method :logger }
end

Zee.app.config :test do
  Mail.defaults { delivery_method :test }
end

Zee.app.config :production do
  # Set the SMTP password.
  mandatory :smtp_password, string

  Mail.defaults do
    delivery_method :smtp, {
      address: "smtp.example.com",
      port: 587,
      user_name: "user",
      password: Zee.app.config.smtp_password
    }
  end
end
