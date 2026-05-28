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
    order = fresh_cart
    order.add_product!(products(:shampoo_wella), 1)
    order.checkout!
    assert_equal "checkout", order.reload.status
  end

  test "checkout! lanza EmptyCartError si el carrito está vacío" do
    assert_raises(Order::EmptyCartError) { fresh_cart.checkout! }
  end

  test "checkout! lanza InvalidTransitionError si el status no es cart" do
    order = orders(:orden_pagada)
    assert_raises(Order::InvalidTransitionError) { order.checkout! }
  end

  # ── mark_paid! ───────────────────────────────────────────────────
  test "mark_paid! actualiza status y descuenta stock" do
    order   = fresh_cart
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
end
