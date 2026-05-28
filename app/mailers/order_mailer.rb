class OrderMailer < ApplicationMailer
  # Sin dominio propio: usar onboarding@resend.dev (solo envía a emails verificados en Resend)
  # Con dominio propio: cambiar a "Studio Graffé <noreply@studiograffe.cl>"
  default from: ENV.fetch("MAILER_FROM", "Studio Graffé <onboarding@resend.dev>")

  # Sends an order confirmation to the customer after a successful payment.
  def confirmation(order)
    @order = order
    @user  = order.user
    @items = order.order_items.includes(:product)

    mail(
      to:      @user.email,
      subject: "✅ Pedido confirmado — #{order.number}"
    )
  end
end
