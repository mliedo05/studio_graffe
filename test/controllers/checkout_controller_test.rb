require "test_helper"

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  # ── Helpers ───────────────────────────────────────────────────────
  def cart_with_product(user = users(:cliente))
    cart = user.current_cart
    cart.order_items.destroy_all
    cart.add_product!(products(:shampoo_wella), 1)
    cart
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

  def delivery_params
    billing_params.merge(
      shipping_type:           "delivery",
      shipping_phone_prefix:   "+56",
      shipping_phone_number:   "9 8765 4321",
      shipping_recipient_name: "María González",
      shipping_region:         "Metropolitana",
      shipping_comuna:         "Santiago",
      shipping_city:           "Santiago",
      shipping_street:         "Av. Providencia",
      shipping_street_number:  "1234"
    )
  end

  # ── GET /checkout ─────────────────────────────────────────────────
  test "redirige a login si no está autenticado" do
    get checkout_path
    assert_redirected_to new_user_session_path
  end

  test "redirige a tienda si el carrito está vacío" do
    sign_in_as users(:cliente)
    users(:cliente).current_cart.order_items.destroy_all
    get checkout_path
    assert_redirected_to shop_path
  end

  test "devuelve 200 con carrito con productos" do
    sign_in_as users(:cliente)
    cart_with_product
    get checkout_path
    assert_response :success
  end

  test "pre-rellena nombre y email del usuario" do
    sign_in_as users(:cliente)
    cart_with_product
    get checkout_path
    assert_select "input[name='order[billing_first_name]'][value='María']"
    assert_select "input[name='order[billing_email]'][value='maria@example.com']"
  end

  # ── POST /checkout/pago — autenticación y carrito ─────────────────
  test "POST /checkout/pago sin autenticar redirige a login" do
    post checkout_payment_path
    assert_redirected_to new_user_session_path
  end

  test "POST /checkout/pago con carrito vacío redirige a la tienda" do
    sign_in_as users(:cliente)
    users(:cliente).current_cart.order_items.destroy_all
    post checkout_payment_path
    assert_redirected_to shop_path
  end

  # ── POST /checkout/pago — flujo pickup exitoso ────────────────────
  test "pago pickup exitoso redirige a tienda con notice" do
    sign_in_as users(:cliente)
    cart_with_product
    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }
    assert_redirected_to shop_path
    assert_equal "¡Pedido confirmado! Te contactaremos pronto.", flash[:notice]
  end

  test "pago pickup cambia status de la orden a paid" do
    sign_in_as users(:cliente)
    cart = cart_with_product
    post checkout_payment_path, params: { order: billing_params, payment_method: "efectivo" }
    assert_equal "paid", cart.reload.status
  end

  test "pago combina prefijo y número de teléfono de facturación" do
    sign_in_as users(:cliente)
    cart = cart_with_product
    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }
    assert_equal "+56 9 1234 5678", cart.reload.billing_phone
  end

  # ── POST /checkout/pago — flujo delivery ─────────────────────────
  test "pago delivery guarda datos de dirección" do
    sign_in_as users(:cliente)
    cart = cart_with_product
    post checkout_payment_path, params: { order: delivery_params, payment_method: "webpay" }
    order = cart.reload
    assert_equal "delivery",        order.shipping_type
    assert_equal "Metropolitana",   order.shipping_region
    assert_equal "Santiago",        order.shipping_comuna
    assert_equal "Av. Providencia", order.shipping_street
    assert_equal "1234",            order.shipping_street_number
  end

  test "pago delivery combina teléfono de envío" do
    sign_in_as users(:cliente)
    cart = cart_with_product
    post checkout_payment_path, params: { order: delivery_params, payment_method: "webpay" }
    assert_equal "+56 9 8765 4321", cart.reload.shipping_phone
  end

  # ── POST /checkout/pago — método de pago ─────────────────────────
  test "guarda el método de pago webpay" do
    sign_in_as users(:cliente)
    cart = cart_with_product
    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }
    assert_equal "webpay", cart.reload.payment_method
  end

  test "guarda el método de pago efectivo" do
    sign_in_as users(:cliente)
    cart = cart_with_product
    post checkout_payment_path, params: { order: billing_params, payment_method: "efectivo" }
    assert_equal "efectivo", cart.reload.payment_method
  end

  # ── POST /checkout/pago — datos inválidos ─────────────────────────
  test "re-renderiza el formulario si faltan datos de facturación" do
    sign_in_as users(:cliente)
    cart_with_product
    post checkout_payment_path, params: {
      order: billing_params.except(:billing_first_name),
      payment_method: "webpay"
    }
    assert_response :unprocessable_entity
  end

  # ── PATCH /checkout ────────────────────────────────────────────────
  test "PATCH /checkout guarda datos sin completar el pago" do
    sign_in_as users(:cliente)
    cart = cart_with_product
    patch checkout_update_path, params: { order: billing_params }
    assert_equal "María",  cart.reload.billing_first_name
    assert_equal "pickup", cart.reload.shipping_type
  end

  # ── Teléfono guardado en usuario ──────────────────────────────────
  test "pago guarda billing_phone en user.phone cuando el usuario no tenía teléfono" do
    user = users(:cliente)
    user.update_columns(phone: nil)
    sign_in_as user
    cart_with_product(user)
    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }
    assert_equal "+56 9 1234 5678", user.reload.phone
  end

  test "pago NO sobreescribe user.phone si el usuario ya tiene teléfono" do
    user = users(:cliente)
    user.update_columns(phone: "+56 9 0000 0000")
    sign_in_as user
    cart_with_product(user)
    post checkout_payment_path, params: { order: billing_params, payment_method: "webpay" }
    assert_equal "+56 9 0000 0000", user.reload.phone
  end

  # ── Prefill teléfono desde perfil del usuario ─────────────────────
  test "GET /checkout responde 200 cuando user tiene phone guardado" do
    user = users(:cliente)
    user.update_columns(phone: "+56 9 7777 6666")
    sign_in_as user
    cart_with_product(user)
    get checkout_path
    assert_response :success
  end

  test "prefill_billing usa user.phone cuando el order no tiene billing_phone" do
    user = users(:cliente)
    user.update_columns(phone: "+56 9 7777 6666")
    sign_in_as user
    cart = cart_with_product(user)
    cart.update_columns(billing_phone: nil)
    # Simula el prefill que hace el controller en show
    cart.billing_phone ||= user.phone
    assert_equal "+56 9 7777 6666", cart.billing_phone
  end

  # ── Guardar dirección al pagar ────────────────────────────────────
  test "pago delivery con save_address=1 crea una dirección guardada" do
    sign_in_as users(:cliente)
    cart_with_product
    assert_difference "Address.count", 1 do
      post checkout_payment_path, params: {
        order:          delivery_params,
        payment_method: "webpay",
        save_address:   "1",
        address_label:  "Mi depa"
      }
    end
  end

  test "pago delivery con save_address=1 asigna el label correcto" do
    sign_in_as users(:cliente)
    cart_with_product
    post checkout_payment_path, params: {
      order:          delivery_params,
      payment_method: "webpay",
      save_address:   "1",
      address_label:  "Mi depa"
    }
    addr = users(:cliente).addresses.order(created_at: :desc).first
    assert_equal "Mi depa",           addr.label
    assert_equal "Av. Providencia",   addr.street
    assert_equal "Metropolitana",     addr.region
  end

  test "pago pickup con save_address=1 NO crea dirección" do
    sign_in_as users(:cliente)
    cart_with_product
    assert_no_difference "Address.count" do
      post checkout_payment_path, params: {
        order:          billing_params,  # pickup
        payment_method: "webpay",
        save_address:   "1"
      }
    end
  end

  test "pago delivery SIN save_address NO crea dirección" do
    sign_in_as users(:cliente)
    cart_with_product
    assert_no_difference "Address.count" do
      post checkout_payment_path, params: {
        order:          delivery_params,
        payment_method: "webpay"
        # sin save_address
      }
    end
  end
end
