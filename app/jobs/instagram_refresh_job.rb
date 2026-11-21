# Refresca el feed de Instagram cada hora (ver config/recurring.yml).
# Si falla, avisa por correo a ADMIN_EMAIL como máximo una vez al día.
class InstagramRefreshJob < ApplicationJob
  queue_as :default

  ALERT_KEY = "instagram_alert_sent"

  def perform
    InstagramService.new.refresh!
    Rails.cache.delete(ALERT_KEY)
  rescue InstagramService::FetchError => e
    Rails.logger.error "[InstagramRefreshJob] #{e.message}"
    return if Rails.cache.read(ALERT_KEY)

    AdminMailer.instagram_failure(e.message).deliver_later
    Rails.cache.write(ALERT_KEY, true, expires_in: 1.day)
  end
end
