require "test_helper"

class CheckoutFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user    = users(:cliente)
    @product = products(:shampoo_wella)
    sign_in_as @user
    @user.current_cart.order_items.destroy_all
  end

  def billing_params
    {
      billing_first_name:      "María",
      billing_last_name:       "González",
      billing_document_type:   "rut",
      billing_document_number: "12.345.678-9",
      billing_email:           "maria@example.com",
      billing_phone_prefix:    "+56",
      billing_phone_number:    "9 1234 5678",
      shipping_type:           "pickup"
    }
  end

  # ── Flujo completo pickup ─────────────────────────────────────────
  test "flujo completo: carrito → checkout → pago → orden pagada" do
    cart = @user.current_cart
    cart.add_product!(@product, 2)

    get checkout_path
    assert_response :success

    post checkout_payment_path,
         params: { order: billing_params, payment_method: "webpay" }
    assert_redirected_to shop_path

    order = cart.reload
    assert_equal "paid",    order.status
    assert_equal "webpay",  order.payment_method
    assert_not_nil           order.transaction_id
    assert_equal 2,          order.order_items.first.quantity
  end

  test "flujo completo con delivery guarda dirección en la orden" do
    cart = @user.current_cart
    cart.add_product!(@product, 1)

    post checkout_payment_path, params: {
      order: billing_params.merge(
        shipping_type:           "delivery",
        shipping_phone_prefix:   "+54",
        shipping_phone_number:   "11 1234 5678",
        shipping_recipient_name: "Laura Pérez",
        shipping_region:         "Valparaíso",
        shipping_comuna:         "Valparaíso",
        shipping_city:           "Valparaíso",
        shipping_street:         "Calle Blanco",
        shipping_street_number:  "500"
      ),
      payment_method: "efectivo"
    }
    assert_redirected_to shop_path

    order = cart.reload
    assert_equal "paid",             order.status
    assert_equal "delivery",         order.shipping_type
    assert_equal "Valparaíso",       order.shipping_region
    assert_equal "Valparaíso",       order.shipping_comuna
    assert_equal "Calle Blanco",     order.shipping_street
    assert_equal "+54 11 1234 5678", order.shipping_phone
  end

  # ── Stock se descuenta al pagar ───────────────────────────────────
  test "el stock del producto se descuenta tras el pago" do
    stock_antes = @product.stock_quantity
    @user.current_cart.add_product!(@product, 3)

    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }

    assert_equal stock_antes - 3, @product.reload.stock_quantity
  end

  # ── Carrito vacío tras pago ───────────────────────────────────────
  test "tras pagar se crea un nuevo carrito vacío" do
    @user.current_cart.add_product!(@product, 1)
    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }

    nuevo = @user.reload.current_cart
    assert_equal "cart", nuevo.status
    assert_equal 0,      nuevo.order_items.count
  end

  # ── Datos de facturación ──────────────────────────────────────────
  test "los datos de facturación quedan grabados en la orden" do
    cart = @user.current_cart
    cart.add_product!(@product, 1)

    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }

    order = cart.reload
    assert_equal "paid",              order.status
    assert_equal "María",             order.billing_first_name
    assert_equal "González",          order.billing_last_name
    assert_equal "rut",               order.billing_document_type
    assert_equal "12.345.678-9",      order.billing_document_number
    assert_equal "maria@example.com", order.billing_email
    assert_equal "+56 9 1234 5678",   order.billing_phone
  end

  # ── Prefijos de teléfono internacionales ──────────────────────────
  test "se guarda correctamente el prefijo de España (+34)" do
    cart = @user.current_cart
    cart.add_product!(@product, 1)

    post checkout_payment_path, params: {
      order: billing_params.merge(billing_phone_prefix: "+34", billing_phone_number: "612 345 678"),
      payment_method: "webpay"
    }

    assert_equal "+34 612 345 678", cart.reload.billing_phone
  end

  test "se guarda correctamente el prefijo de Venezuela (+58)" do
    cart = @user.current_cart
    cart.add_product!(@product, 1)

    post checkout_payment_path, params: {
      order: billing_params.merge(billing_phone_prefix: "+58", billing_phone_number: "412 123 4567"),
      payment_method: "efectivo"
    }

    assert_equal "+58 412 123 4567", cart.reload.billing_phone
  end

  test "se guarda correctamente el prefijo de Argentina (+54)" do
    cart = @user.current_cart
    cart.add_product!(@product, 1)

    post checkout_payment_path, params: {
      order: billing_params.merge(billing_phone_prefix: "+54", billing_phone_number: "11 4567 8901"),
      payment_method: "webpay"
    }

    assert_equal "+54 11 4567 8901", cart.reload.billing_phone
  end

  # ── Acceso sin autenticación ──────────────────────────────────────
  test "usuario no autenticado no puede acceder al checkout" do
    delete destroy_user_session_path
    get checkout_path
    assert_redirected_to new_user_session_path
  end

  # ── Carrito vacío ─────────────────────────────────────────────────
  test "no se puede acceder al checkout con carrito vacío" do
    get checkout_path
    assert_redirected_to shop_path
    assert_equal "Tu carrito está vacío.", flash[:alert]
  end
end
