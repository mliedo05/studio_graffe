class CartController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = CartService.cart_for(current_user)
    @cart.order_items.includes(:product)
  end
end
