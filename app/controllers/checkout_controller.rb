class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :load_cart
  before_action :ensure_cart_not_empty

  def show
    @order = @cart
    prefill_billing
  end

  def update
    @order = @cart

    if @order.update(combined_checkout_params)
      redirect_to checkout_path, notice: "Datos guardados."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def payment
    @order = @cart

    if @order.update(combined_checkout_params)
      @order.checkout!
      @order.mark_paid!(
        transaction_id: "SIM-#{SecureRandom.hex(6).upcase}",
        payment_method: params[:payment_method].presence || "webpay"
      )
      redirect_to shop_path, notice: "¡Pedido confirmado! Te contactaremos pronto."
    else
      render :show, status: :unprocessable_entity
    end
  rescue Order::EmptyCartError, Order::InvalidTransitionError => e
    redirect_to cart_path, alert: e.message
  end

  private

  def load_cart
    @cart = CartService.cart_for(current_user)
  end

  def ensure_cart_not_empty
    redirect_to shop_path, alert: "Tu carrito está vacío." if @cart.order_items.empty?
  end

  def prefill_billing
    @order.billing_first_name ||= current_user.first_name
    @order.billing_last_name  ||= current_user.last_name
    @order.billing_email      ||= current_user.email
    @order.shipping_type      ||= "pickup"
  end

  # Combine country prefix + local number into a single phone string
  def combined_checkout_params
    p = checkout_params.to_h

    billing_prefix = params.dig(:order, :billing_phone_prefix).to_s.strip
    billing_number = params.dig(:order, :billing_phone_number).to_s.strip
    p["billing_phone"] = "#{billing_prefix} #{billing_number}".strip if billing_number.present?

    shipping_prefix = params.dig(:order, :shipping_phone_prefix).to_s.strip
    shipping_number = params.dig(:order, :shipping_phone_number).to_s.strip
    p["shipping_phone"] = "#{shipping_prefix} #{shipping_number}".strip if shipping_number.present?

    p
  end

  def checkout_params
    params.require(:order).permit(
      :billing_first_name, :billing_last_name,
      :billing_document_type, :billing_document_number,
      :billing_email,
      :shipping_type,
      :shipping_recipient_name,
      :shipping_region, :shipping_comuna, :shipping_city,
      :shipping_street, :shipping_street_number, :shipping_apartment
    )
  end
end
