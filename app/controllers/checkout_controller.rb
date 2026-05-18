class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :load_cart
  before_action :ensure_cart_not_empty

  def show
    # Pre-fill from user profile or last order
    @order = @cart
    prefill_billing
  end

  def update
    @order = @cart

    if @order.update(checkout_params)
      redirect_to checkout_path, notice: "Datos guardados."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def payment
    @order = @cart

    if @order.update(checkout_params)
      @order.checkout!
      # TODO: integrate real payment gateway
      @order.mark_paid!(transaction_id: "SIM-#{SecureRandom.hex(6).upcase}", payment_method: params[:payment_method].presence || "webpay")
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

  def checkout_params
    params.require(:order).permit(
      :billing_first_name, :billing_last_name,
      :billing_document_type, :billing_document_number,
      :billing_email, :billing_phone,
      :shipping_type,
      :shipping_recipient_name, :shipping_phone,
      :shipping_region, :shipping_comuna, :shipping_city,
      :shipping_street, :shipping_street_number, :shipping_apartment
    )
  end
end
