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

  # JSON endpoint for the cart drawer preview
  def drawer_data
    cart  = CartService.cart_for(current_user)
    items = cart.order_items.includes(:product).map do |item|
      {
        id:          item.id,
        name:        item.product.name,
        quantity:    item.quantity,
        unit_price:  helpers.humanized_money_with_symbol(item.unit_price),
        total_price: helpers.humanized_money_with_symbol(item.total_price),
        image_url:   item.product.image.attached? ? url_for(item.product.image) : nil
      }
    end

    render json: {
      count:    cart.item_count,
      subtotal: helpers.humanized_money_with_symbol(cart.subtotal),
      items:    items
    }
  end
end
