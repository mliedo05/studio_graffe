require "test_helper"

# Prueba el flujo completo: browse tienda → agregar → ver carrito → quitar producto
class CartFlowTest < ActionDispatch::IntegrationTest
  def setup
    @cliente = users(:cliente)
    @product = products(:shampoo_wella)
    sign_in_as @cliente
  end

  test "usuario puede navegar la tienda sin autenticar" do
    delete destroy_user_session_path
    get shop_path
    assert_response :success
  end

  test "flujo completo: agregar producto, ver carrito, eliminar producto" do
    # Agrega producto
    post cart_add_item_path, params: { product_id: @product.id, quantity: 1 }

    cart = @cliente.current_cart.reload
    assert_equal 1, cart.item_count
    assert_equal @product.price_cents, cart.total_cents

    # Ve el carrito
    get cart_path
    assert_response :success

    # Elimina el producto
    item = cart.order_items.find_by(product: @product)
    delete cart_item_path(item)
    assert_equal 0, @cliente.current_cart.reload.item_count
  end

  test "agregar el mismo producto suma la cantidad" do
    post cart_add_item_path, params: { product_id: @product.id, quantity: 1 }
    post cart_add_item_path, params: { product_id: @product.id, quantity: 2 }

    cart = @cliente.current_cart.reload
    item = cart.order_items.find_by(product: @product)
    assert_equal 3, item.quantity
    assert_equal @product.price_cents * 3, cart.total_cents
  end

  test "usuario no autenticado es redirigido al agregar al carrito" do
    delete destroy_user_session_path
    post cart_add_item_path, params: { product_id: @product.id, quantity: 1 }
    assert_redirected_to new_user_session_path
  end
end
