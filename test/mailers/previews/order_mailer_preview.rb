# Previsualiza los emails en: http://localhost:3000/rails/mailers/order_mailer
class OrderMailerPreview < ActionMailer::Preview

  # http://localhost:3000/rails/mailers/order_mailer/confirmation
  def confirmation
    # Usa la primera orden pagada que exista en la BD de desarrollo
    order = Order.where(status: "paid").includes(order_items: :product, user: {}).last ||
            Order.where.not(status: "cart").includes(order_items: :product, user: {}).last

    OrderMailer.confirmation(order)
  end

end
