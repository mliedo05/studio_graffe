require "test_helper"

class CartControllerTest < ActionDispatch::IntegrationTest
  test "GET /carrito redirige a login si no está autenticado" do
    get cart_path
    assert_redirected_to new_user_session_path
  end

  test "GET /carrito devuelve 200 si está autenticado" do
    sign_in_as users(:cliente)
    get cart_path
    assert_response :success
  end
end

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  test "POST /carrito/agregar redirige a login si no está autenticado" do
    post cart_add_item_path, params: { product_id: products(:shampoo_wella).id, quantity: 1 }
    assert_redirected_to new_user_session_path
  end

  test "POST /carrito/agregar agrega producto para usuario autenticado" do
    sign_in_as users(:cliente)
    product = products(:shampoo_wella)

    assert_difference "OrderItem.count", 1 do
      post cart_add_item_path, params: { product_id: product.id, quantity: 1 }
    end
  end

  test "POST /carrito/agregar redirige al carrito si no es turbo_stream" do
    sign_in_as users(:cliente)
    post cart_add_item_path, params: { product_id: products(:shampoo_wella).id, quantity: 1 }
    assert_redirected_to shop_path
  end

  test "DELETE /carrito/items/:id elimina el item del carrito" do
    sign_in_as users(:cliente)
    product = products(:shampoo_wella)
    cart    = users(:cliente).current_cart
    cart.add_product!(product, 1)
    item = cart.order_items.find_by(product: product)

    assert_difference "OrderItem.count", -1 do
      delete cart_item_path(item)
    end
    assert_redirected_to cart_path
  end
end
