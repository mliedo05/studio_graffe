class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Studio Graffé <onboarding@resend.dev>")
  layout "mailer"
end
