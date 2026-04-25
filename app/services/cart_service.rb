class CartService
  def self.cart_for(user)
    user.current_cart
  end

  def self.add_item(user:, product_id:, quantity: 1)
    product = Product.find(product_id)
    cart    = cart_for(user)
    # Lanza Order::OutOfStockError si no hay stock suficiente
    # Lanza ArgumentError si quantity <= 0
    cart.add_product!(product, quantity.to_i)
    cart
  end

  def self.remove_item(user:, item_id:)
    cart = cart_for(user)
    item = cart.order_items.find(item_id)
    cart.remove_product!(item.product)
    cart
  end

  def self.checkout(user)
    cart = cart_for(user)
    # Lanza Order::EmptyCartError si el carrito está vacío
    # Lanza Order::InvalidTransitionError si ya no es un carrito activo
    cart.checkout!
    cart
  end
end
