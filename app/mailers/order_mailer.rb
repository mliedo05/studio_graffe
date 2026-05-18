class OrderMailer < ApplicationMailer
  default from: "Studio Graffé <noreply@studiograffe.cl>"

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
