# Reintenta los correos que fallan (por ejemplo, si Resend no responde) y
# deja el error registrado en el log en vez de perderlo en silencio.
Rails.application.config.after_initialize do
  ActionMailer::MailDeliveryJob.retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
    Rails.logger.error "[Mail] No se pudo enviar #{job.arguments.first(2).join('#')} tras 5 intentos: #{error.class} — #{error.message}"
  end
end

ActiveSupport::Notifications.subscribe("deliver.action_mailer") do |event|
  Rails.logger.info "[Mail] Enviado #{event.payload[:mailer]} a #{Array(event.payload[:to]).size} destinatario(s)"
end
