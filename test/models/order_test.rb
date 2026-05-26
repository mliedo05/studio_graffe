require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def fresh_cart
    Order.create!(
      user: users(:admin),
      number: "ORD-#{SecureRandom.hex(4).upcase}",
      status: "cart",
      payment_status: "pending",
      subtotal_cents: 0,
      total_cents: 0
    )
  end

  # Añade los campos de facturación mínimos para poder llamar checkout!
  def with_billing(order)
    order.update_columns(
      billing_first_name:      "Test",
      billing_last_name:       "User",
      billing_document_type:   "rut",
      billing_document_number: "11.111.111-1",
      billing_email:           "test@example.com",
      billing_phone:           "+56 9 0000 0000",
      shipping_type:           "pickup"
    )
    order
  end

  # ── Validaciones básicas ──────────────────────────────────────────
  test "válido con atributos correctos" do
    assert Order.new(
      user: users(:admin), number: "ORD-VALIDO1",
      status: "cart", payment_status: "pending"
    ).valid?
  end

  test "inválido sin number" do
    order = orders(:carrito_maria)
    order.number = nil
    assert_not order.valid?
  end

  test "inválido con number duplicado" do
    order = Order.new(user: users(:admin), number: orders(:carrito_maria).number,
                      status: "cart", payment_status: "pending")
    assert_not order.valid?
    assert_includes order.errors[:number], "has already been taken"
  end

  test "inválido con status desconocido" do
    order = orders(:carrito_maria)
    order.status = "unknown_status"
    assert_not order.valid?
  end

  test "inválido con payment_status desconocido" do
    order = orders(:carrito_maria)
    order.payment_status = "unknown"
    assert_not order.valid?
  end

  # ── add_product! ─────────────────────────────────────────────────
  test "add_product! agrega producto y recalcula el total" do
    order   = fresh_cart
    product = products(:shampoo_wella)

    order.add_product!(product, 2)

    item = order.order_items.find_by(product: product)
    assert_equal 2, item.quantity
    assert_equal product.price_cents * 2, order.reload.total_cents
  end

  test "add_product! incrementa cantidad si el producto ya existe" do
    order   = fresh_cart
    product = products(:shampoo_wella)

    order.add_product!(product, 1)
    order.add_product!(product, 2)

    assert_equal 3, order.order_items.find_by(product: product).quantity
  end

  test "add_product! lanza ArgumentError con cantidad 0" do
    assert_raises(ArgumentError) { fresh_cart.add_product!(products(:shampoo_wella), 0) }
  end

  test "add_product! lanza ArgumentError con cantidad negativa" do
    assert_raises(ArgumentError) { fresh_cart.add_product!(products(:shampoo_wella), -1) }
  end

  test "add_product! lanza OutOfStockError si no hay stock" do
    assert_raises(Order::OutOfStockError) do
      fresh_cart.add_product!(products(:olaplex), 1)  # stock_quantity: 0
    end
  end

  test "add_product! lanza OutOfStockError si se pide más que el stock" do
    product = products(:shampoo_wella)  # stock: 10
    assert_raises(Order::OutOfStockError) do
      fresh_cart.add_product!(product, product.stock_quantity + 1)
    end
  end

  # ── remove_product! ───────────────────────────────────────────────
  test "remove_product! elimina el producto y recalcula a 0" do
    order   = fresh_cart
    product = products(:shampoo_wella)
    order.add_product!(product, 1)

    order.remove_product!(product)

    assert_nil order.order_items.find_by(product: product)
    assert_equal 0, order.reload.total_cents
  end

  # ── checkout! ────────────────────────────────────────────────────
  test "checkout! cambia status a checkout" do
    order = with_billing(fresh_cart)
    order.add_product!(products(:shampoo_wella), 1)
    order.checkout!
    assert_equal "checkout", order.reload.status
  end

  test "checkout! lanza EmptyCartError si el carrito está vacío" do
    assert_raises(Order::EmptyCartError) { with_billing(fresh_cart).checkout! }
  end

  test "checkout! lanza InvalidTransitionError si el status no es cart" do
    order = orders(:orden_pagada)
    assert_raises(Order::InvalidTransitionError) { order.checkout! }
  end

  # ── mark_paid! ───────────────────────────────────────────────────
  test "mark_paid! actualiza status y descuenta stock" do
    order   = with_billing(fresh_cart)
    product = products(:shampoo_wella)
    stock_inicial = product.stock_quantity
    order.add_product!(product, 1)
    order.checkout!

    order.mark_paid!(transaction_id: "AUTH999", payment_method: "webpay")

    assert_equal "paid",           order.reload.status
    assert_equal "paid",           order.payment_status
    assert_equal stock_inicial - 1, product.reload.stock_quantity
  end

  test "mark_paid! lanza InvalidTransitionError si no está en checkout" do
    order = fresh_cart
    assert_raises(Order::InvalidTransitionError) do
      order.mark_paid!(transaction_id: "AUTH999", payment_method: "webpay")
    end
  end

  test "item_count devuelve total de unidades" do
    assert_equal 1, orders(:orden_pagada).item_count
  end

  # ── paid? ─────────────────────────────────────────────────────────

  test "paid? retorna true cuando status es paid" do
    assert orders(:orden_pagada).paid?
  end

  test "paid? retorna false cuando status es cart" do
    assert_not orders(:carrito_maria).paid?
  end

  test "paid? retorna false cuando status es checkout" do
    order = fresh_cart
    with_billing(order)
    order.order_items.create!(product: products(:shampoo_wella), quantity: 1,
                              unit_price_cents: 100, total_price_cents: 100)
    order.checkout!
    assert_not order.paid?
  end

  # ── cancel_failed_payment! ─────────────────────────────────────────

  def checkout_order_for_cancel
    order = fresh_cart
    with_billing(order)
    order.order_items.create!(product: products(:shampoo_wella), quantity: 1,
                              unit_price_cents: 10_000_00, total_price_cents: 10_000_00)
    order.recalculate!
    order.checkout!
    order
  end

  test "cancel_failed_payment! marca la orden como cancelled" do
    order = checkout_order_for_cancel
    order.cancel_failed_payment!
    assert_equal "cancelled", order.reload.status
  end

  test "cancel_failed_payment! marca payment_status como failed" do
    order = checkout_order_for_cancel
    order.cancel_failed_payment!
    assert_equal "failed", order.reload.payment_status
  end

  test "cancel_failed_payment! crea un nuevo carrito para el usuario" do
    order = checkout_order_for_cancel
    user  = order.user
    order.cancel_failed_payment!
    new_cart = user.reload.current_cart
    assert_equal "cart", new_cart.status
  end

  test "cancel_failed_payment! copia los items al nuevo carrito" do
    order = checkout_order_for_cancel
    user  = order.user
    expected = order.order_items.map { |i| [ i.product_id, i.quantity ] }
    order.cancel_failed_payment!
    actual = user.reload.current_cart.order_items.map { |i| [ i.product_id, i.quantity ] }
    assert_equal expected.sort, actual.sort
  end

  test "cancel_failed_payment! lanza error si la orden no está en checkout" do
    order = fresh_cart
    order.order_items.create!(product: products(:shampoo_wella), quantity: 1,
                              unit_price_cents: 100, total_price_cents: 100)
    assert_raises Order::InvalidTransitionError do
      order.cancel_failed_payment!
    end
  end

  # ── Regresión: un solo carrito por usuario ─────────────────────────
  # Antes del fix, cancel_failed_payment! creaba un carrito nuevo con
  # orders.create! en lugar de reutilizar el existente, lo que provocaba
  # N carritos huérfanos por usuario y rompía toda la navegación posterior.

  test "cancel_failed_payment! no crea un segundo carrito si ya existe uno" do
    order = checkout_order_for_cancel
    user  = order.user

    # Asegurar que no queda ningún carrito previo
    user.orders.where(status: "cart").destroy_all

    order.cancel_failed_payment!

    assert_equal 1, user.orders.where(status: "cart").count,
      "No debe existir más de un carrito activo por usuario"
  end

  test "dos pagos rechazados consecutivos no generan carritos duplicados" do
    user = users(:cliente)
    product = products(:shampoo_wella)
    user.orders.where(status: "cart").destroy_all

    # Primer intento fallido
    cart1 = user.current_cart
    cart1.add_product!(product, 1)
    with_billing(cart1)
    cart1.checkout!
    cart1.cancel_failed_payment!

    assert_equal 1, user.orders.where(status: "cart").count, "Después del 1er rechazo debe haber exactamente 1 carrito"

    # Segundo intento fallido
    cart2 = user.current_cart
    with_billing(cart2)
    cart2.checkout!
    cart2.cancel_failed_payment!

    assert_equal 1, user.orders.where(status: "cart").count, "Después del 2do rechazo debe haber exactamente 1 carrito"
  end

  test "pago exitoso tras un rechazo deja exactamente un carrito nuevo vacío" do
    user = users(:cliente)
    product = products(:shampoo_wella)
    user.orders.where(status: "cart").destroy_all

    # Rechazo previo (crea carrito de reintento con el producto)
    cart1 = user.current_cart
    cart1.add_product!(product, 1)
    with_billing(cart1)
    cart1.checkout!
    cart1.cancel_failed_payment!

    # El usuario retoma el carrito de reintento y paga con éxito
    cart2 = user.current_cart
    with_billing(cart2)
    cart2.checkout!
    cart2.mark_paid!(transaction_id: "TXN-001", payment_method: "getnet")

    # El carrito se crea bajo demanda al acceder (simula la primera visita post-pago)
    new_cart = user.current_cart
    assert_equal "cart", new_cart.status, "Debe existir un carrito activo tras el pago"
    assert_equal 0, new_cart.order_items.count, "El carrito nuevo debe estar vacío"
    assert_equal 1, user.orders.where(status: "cart").count, "No debe haber más de un carrito activo"
  end
end
