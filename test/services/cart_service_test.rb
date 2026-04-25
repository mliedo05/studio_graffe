require "test_helper"

class CartServiceTest < ActiveSupport::TestCase
  def setup
    @user    = users(:admin)
    @product = products(:shampoo_wella)   # stock: 10
    @no_stock_product = products(:olaplex) # stock: 0
  end

  # ── cart_for ──────────────────────────────────────────────────────
  test "cart_for crea carrito si el usuario no tiene uno" do
    cart = CartService.cart_for(@user)
    assert_equal "cart", cart.status
    assert_equal @user,  cart.user
  end

  test "cart_for devuelve el mismo carrito en llamadas sucesivas" do
    cart1 = CartService.cart_for(@user)
    cart2 = CartService.cart_for(@user)
    assert_equal cart1.id, cart2.id
  end

  # ── add_item ──────────────────────────────────────────────────────
  test "add_item agrega el producto y devuelve carrito actualizado" do
    cart = CartService.add_item(user: @user, product_id: @product.id, quantity: 2)
    item = cart.order_items.find_by(product: @product)
    assert_equal 2, item.quantity
    assert_equal @product.price_cents * 2, cart.total_cents
  end

  test "add_item usa quantity 1 por defecto" do
    cart = CartService.add_item(user: @user, product_id: @product.id)
    assert_equal 1, cart.order_items.find_by(product: @product).quantity
  end

  test "add_item lanza RecordNotFound si el producto no existe" do
    assert_raises(ActiveRecord::RecordNotFound) do
      CartService.add_item(user: @user, product_id: 999999)
    end
  end

  test "add_item lanza OutOfStockError si no hay stock" do
    assert_raises(Order::OutOfStockError) do
      CartService.add_item(user: @user, product_id: @no_stock_product.id)
    end
  end

  test "add_item lanza ArgumentError con cantidad 0" do
    assert_raises(ArgumentError) do
      CartService.add_item(user: @user, product_id: @product.id, quantity: 0)
    end
  end

  # ── remove_item ───────────────────────────────────────────────────
  test "remove_item elimina el producto del carrito" do
    CartService.add_item(user: @user, product_id: @product.id, quantity: 1)
    item = CartService.cart_for(@user).order_items.find_by(product: @product)
    CartService.remove_item(user: @user, item_id: item.id)
    assert_equal 0, CartService.cart_for(@user).item_count
  end

  test "remove_item lanza RecordNotFound con item_id inválido" do
    assert_raises(ActiveRecord::RecordNotFound) do
      CartService.remove_item(user: @user, item_id: 999999)
    end
  end

  # ── checkout ──────────────────────────────────────────────────────
  test "checkout cambia el status a checkout" do
    CartService.add_item(user: @user, product_id: @product.id, quantity: 1)
    cart = CartService.checkout(@user)
    assert_equal "checkout", cart.reload.status
  end

  test "checkout lanza EmptyCartError si el carrito está vacío" do
    assert_raises(Order::EmptyCartError) do
      CartService.checkout(@user)
    end
  end
end
