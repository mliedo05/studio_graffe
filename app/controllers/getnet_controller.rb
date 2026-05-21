class GetnetController < ApplicationController
  # Getnet notification webhook — no CSRF, no auth required
  skip_before_action :verify_authenticity_token, only: :notification

  # GET /getnet/retorno?order=ORD-XXXXXXXX
  # Called when the user clicks "Volver al comercio" in Getnet.
  def return_payment
    order = Order.find_by(number: params[:order])

    if order.nil?
      redirect_to shop_path, alert: "No se encontró el pedido." and return
    end

    # If already paid (notification arrived first), just redirect
    if order.paid?
      redirect_to shop_path, notice: "¡Pedido confirmado! Te enviamos un correo con el detalle." and return
    end

    # Query Getnet for the current status
    service = GetnetService.new
    if service.approved?(order.payment_token)
      confirm_order!(order)
      redirect_to shop_path, notice: "¡Pedido confirmado! Te enviamos un correo con el detalle."
    else
      order.update(status: "cart")
      redirect_to checkout_path, alert: "El pago no fue aprobado. Puedes intentarlo nuevamente."
    end
  rescue GetnetService::GetnetError => e
    Rails.logger.error "[Getnet] Error en retorno: #{e.message}"
    redirect_to checkout_path, alert: "Hubo un problema al verificar el pago. Contáctanos si el cargo fue realizado."
  end

  # POST /getnet/notificacion
  # Asynchronous webhook sent by Getnet when the payment status is final.
  def notification
    body = JSON.parse(request.body.read)
    request_id = body.dig("requestId")&.to_s
    status     = body.dig("status", "status")

    order = Order.find_by(payment_token: request_id)

    if order && status == "APPROVED" && !order.paid?
      confirm_order!(order)
    end

    head :ok
  rescue => e
    Rails.logger.error "[Getnet] Error en notificación: #{e.message}"
    head :ok  # Always return 200 to avoid Getnet retrying
  end

  private

  def confirm_order!(order)
    order.checkout! unless order.checkout?
    order.mark_paid!(
      transaction_id: order.payment_token,
      payment_method: "getnet"
    )
    current_user&.update(phone: order.billing_phone) if order.billing_phone.present? && current_user&.phone.blank?
    OrderMailer.confirmation(order).deliver_later
  end
end
