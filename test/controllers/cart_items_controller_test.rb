require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user    = users(:cliente)
    @product = products(:shampoo_wella)
    @cart    = orders(:carrito_maria)
  end

  def create_cart_item(quantity: 2)
    OrderItem.create!(
      order:             @cart,
      product:           @product,
      quantity:          quantity,
      unit_price_cents:  @product.price_cents,
      total_price_cents: @product.price_cents * quantity
    )
  end

  # --- unauthenticated ---

  test "PATCH update redirige a login cuando no autenticado" do
    item = create_cart_item
    patch update_cart_item_path(item), params: { quantity: 3 }
    assert_redirected_to new_user_session_path
  end

  # --- increase quantity ---

  test "PATCH update con nueva cantidad válida redirige al carrito (HTML)" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 1)
    patch update_cart_item_path(item), params: { quantity: 3 }
    assert_redirected_to cart_path
  end

  test "PATCH update aumenta la cantidad del item" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 1)
    patch update_cart_item_path(item), params: { quantity: 3 }
    assert_equal 3, item.reload.quantity
  end

  # --- decrease quantity ---

  test "PATCH update disminuye la cantidad del item" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 5)
    patch update_cart_item_path(item), params: { quantity: 2 }
    assert_redirected_to cart_path
    assert_equal 2, item.reload.quantity
  end

  # --- quantity <= 0 removes item ---

  test "PATCH update con quantity 0 elimina el item y redirige al carrito" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 2)
    assert_difference "OrderItem.count", -1 do
      patch update_cart_item_path(item), params: { quantity: 0 }
    end
    assert_redirected_to cart_path
  end

  test "PATCH update con quantity negativa elimina el item" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 2)
    assert_difference "OrderItem.count", -1 do
      patch update_cart_item_path(item), params: { quantity: -1 }
    end
    assert_redirected_to cart_path
  end

  # --- out of stock ---

  test "PATCH update con cantidad mayor al stock redirige con alerta" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 1)
    patch update_cart_item_path(item), params: { quantity: 999 }
    assert_redirected_to cart_path
    assert_not_nil flash[:alert]
  end

  # --- turbo_stream format ---

  test "PATCH update con turbo_stream y cantidad válida responde turbo_stream" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 1)
    patch update_cart_item_path(item),
          params: { quantity: 2 },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "PATCH update con turbo_stream y quantity 0 responde turbo_stream destroy" do
    sign_in_as(@user)
    item = create_cart_item(quantity: 2)
    patch update_cart_item_path(item),
          params: { quantity: 0 },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end
end
