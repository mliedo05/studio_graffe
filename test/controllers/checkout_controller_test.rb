require "test_helper"

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  test "GET /checkout redirige a login si no está autenticado" do
    get checkout_path
    assert_redirected_to new_user_session_path
  end

  test "GET /checkout redirige a tienda si el carrito está vacío" do
    sign_in_as users(:cliente)
    get checkout_path
    assert_redirected_to shop_path
  end

  test "GET /checkout devuelve 200 si el carrito tiene productos" do
    sign_in_as users(:cliente)
    cart = users(:cliente).current_cart
    cart.add_product!(products(:shampoo_wella), 1)
    get checkout_path
    assert_response :success
  end

  test "POST /checkout/pago con carrito vacío redirige al carrito" do
    sign_in_as users(:cliente)
    post checkout_payment_path
    assert_redirected_to cart_path
  end
end
