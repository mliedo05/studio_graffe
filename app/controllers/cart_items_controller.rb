class CartItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    @cart = CartService.add_item(
      user:       current_user,
      product_id: params[:product_id],
      quantity:   params[:quantity] || 1
    )
    @product   = Product.find(params[:product_id])
    @cart_item = @cart.order_items.find_by(product: @product)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: shop_path, notice: "Producto agregado al carrito." }
    end
  rescue Order::OutOfStockError, ArgumentError => e
    redirect_back fallback_location: shop_path, alert: e.message
  end

  def update
    quantity = params[:quantity].to_i
    @item    = OrderItem.find(params[:id])
    @product = @item.product
    @cart    = CartService.cart_for(current_user)

    if quantity <= 0
      CartService.remove_item(user: current_user, item_id: @item.id)
      @cart      = CartService.cart_for(current_user)
      @cart_item = nil
      respond_to do |format|
        format.turbo_stream { render :destroy }
        format.html { redirect_to cart_path }
      end
    else
      raise Order::OutOfStockError, "Sin stock suficiente." if quantity > @product.stock_quantity
      @item.update!(quantity: quantity, total_price_cents: @item.unit_price_cents * quantity)
      @cart.recalculate!
      @item      = @item.reload
      @cart      = @cart.reload
      @cart_item = @item
      respond_to do |format|
        format.turbo_stream { render :update }
        format.html { redirect_to cart_path }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path
  rescue Order::OutOfStockError => e
    redirect_to cart_path, alert: e.message
  end

  def destroy
    @item      = OrderItem.find(params[:id])
    @product   = @item.product
    @cart_item = nil
    @cart      = CartService.remove_item(user: current_user, item_id: params[:id])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path, notice: "Producto eliminado del carrito." }
    end
  end
end
