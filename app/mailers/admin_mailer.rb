# Avisos internos para la administración del sitio.
class AdminMailer < ApplicationMailer
  def instagram_failure(error_message)
    @error_message = error_message
    to = ENV["ADMIN_EMAIL"].presence
    return if to.blank?

    mail(to: to, subject: "[Studio Graffé] El feed de Instagram dejó de actualizarse")
  end
end
