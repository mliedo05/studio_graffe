require "test_helper"

class CartControllerTest < ActionDispatch::IntegrationTest
  # ── GET /carrito ─────────────────────────────────────────────────

  test "GET /carrito redirige a login si no está autenticado" do
    get cart_path
    assert_redirected_to new_user_session_path
  end

  test "GET /carrito devuelve 200 si está autenticado" do
    sign_in_as users(:cliente)
    get cart_path
    assert_response :success
  end

  # ── DELETE /carrito/vaciar ────────────────────────────────────────

  test "DELETE /carrito/vaciar redirige a login si no está autenticado" do
    delete cart_clear_path
    assert_redirected_to new_user_session_path
  end

  test "DELETE /carrito/vaciar elimina todos los items del carrito" do
    sign_in_as users(:cliente)
    cart = users(:cliente).current_cart
    cart.add_product!(products(:shampoo_wella), 2)
    cart.add_product!(products(:acondicionador_wella), 1)
    assert cart.order_items.count >= 2

    delete cart_clear_path
    assert_equal 0, cart.reload.order_items.count
  end

  test "DELETE /carrito/vaciar redirige al carrito con notice" do
    sign_in_as users(:cliente)
    users(:cliente).current_cart.add_product!(products(:shampoo_wella), 1)

    delete cart_clear_path
    assert_redirected_to cart_path
    assert_equal "Carrito vaciado.", flash[:notice]
  end

  test "DELETE /carrito/vaciar recalcula totales a cero" do
    sign_in_as users(:cliente)
    cart = users(:cliente).current_cart
    cart.add_product!(products(:shampoo_wella), 1)

    delete cart_clear_path
    assert_equal 0, cart.reload.total_cents
  end

  # ── GET /carrito/datos (drawer JSON) ─────────────────────────────

  test "GET /carrito/datos redirige a login si no está autenticado" do
    get cart_drawer_data_path
    assert_redirected_to new_user_session_path
  end

  test "GET /carrito/datos devuelve JSON con estructura correcta" do
    sign_in_as users(:cliente)
    get cart_drawer_data_path
    assert_response :success
    assert_equal "application/json", response.media_type
    body = JSON.parse(response.body)
    assert body.key?("count")
    assert body.key?("subtotal")
    assert body.key?("items")
    assert_kind_of Array, body["items"]
  end

  test "GET /carrito/datos devuelve count 0 con carrito vacío" do
    sign_in_as users(:cliente)
    users(:cliente).current_cart.order_items.destroy_all
    get cart_drawer_data_path
    body = JSON.parse(response.body)
    assert_equal 0, body["count"]
    assert_empty body["items"]
  end

  test "GET /carrito/datos incluye productos del carrito" do
    sign_in_as users(:cliente)
    product = products(:shampoo_wella)
    cart    = users(:cliente).current_cart
    cart.order_items.destroy_all
    cart.add_product!(product, 3)

    get cart_drawer_data_path
    body  = JSON.parse(response.body)
    item  = body["items"].first

    assert_equal 3,              body["count"]
    assert_equal product.name,   item["name"]
    assert_equal 3,              item["quantity"]
    assert item.key?("unit_price")
    assert item.key?("total_price")
    assert item.key?("image_url")
  end

  test "GET /carrito/datos refleja múltiples productos" do
    sign_in_as users(:cliente)
    cart = users(:cliente).current_cart
    cart.order_items.destroy_all
    cart.add_product!(products(:shampoo_wella), 1)
    cart.add_product!(products(:acondicionador_wella), 2)

    get cart_drawer_data_path
    body = JSON.parse(response.body)
    assert_equal 3,              body["count"]   # 1 + 2 items
    assert_equal 2,              body["items"].size
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

  test "POST /carrito/agregar redirige al shop si no es turbo_stream" do
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
