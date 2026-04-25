class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :load_cart

  def show
    redirect_to shop_path, alert: "Tu carrito está vacío." if @cart.order_items.empty?
  end

  def payment
    CartService.checkout(current_user)
    redirect_to shop_path, notice: "Pago procesado (modo simulación)."
  rescue Order::EmptyCartError, Order::InvalidTransitionError => e
    redirect_to cart_path, alert: e.message
  end

  private

  def load_cart
    @cart = CartService.cart_for(current_user)
  end
end
