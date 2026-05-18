class CartController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = CartService.cart_for(current_user)
    @cart.order_items.includes(:product)
  end

  def clear
    @cart = CartService.cart_for(current_user)
    @cart.order_items.destroy_all
    @cart.recalculate!
    redirect_to cart_path, notice: "Carrito vaciado."
  end
end
