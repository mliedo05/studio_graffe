require "test_helper"

class OrderItemTest < ActiveSupport::TestCase

  def item_with_cost(price_cents:, cost_cents:, quantity: 1)
    OrderItem.new(
      order:             orders(:orden_pagada),
      product:           products(:shampoo_wella),
      quantity:          quantity,
      unit_price_cents:  price_cents,
      total_price_cents: price_cents * quantity,
      unit_cost_cents:   cost_cents,
      total_cost_cents:  cost_cents * quantity
    )
  end

  # ── margin_cents ──────────────────────────────────────────────────

  test "margin_cents calcula la diferencia entre precio y costo" do
    item = item_with_cost(price_cents: 18990, cost_cents: 9000, quantity: 1)
    assert_equal 9990, item.margin_cents
  end

  test "margin_cents con múltiples unidades usa totales" do
    item = item_with_cost(price_cents: 18990, cost_cents: 9000, quantity: 3)
    # total_price = 56.970, total_cost = 27.000, margen = 29.970
    assert_equal 29970, item.margin_cents
  end

  test "margin_cents retorna nil cuando no hay costo registrado" do
    item = item_with_cost(price_cents: 18990, cost_cents: 9000)
    item.total_cost_cents = nil
    assert_nil item.margin_cents
  end

  test "margin_cents puede ser negativo si se vendió por debajo del costo" do
    item = item_with_cost(price_cents: 5000, cost_cents: 9000, quantity: 1)
    assert_equal(-4000, item.margin_cents)
  end

  # ── margin_percent ────────────────────────────────────────────────

  test "margin_percent calcula el porcentaje sobre el costo" do
    # precio $18.990, costo $9.000 → margen $9.990 → 111.0% sobre costo
    item = item_with_cost(price_cents: 18000, cost_cents: 9000)
    assert_equal 100.0, item.margin_percent
  end

  test "margin_percent retorna nil cuando no hay costo" do
    item = item_with_cost(price_cents: 18990, cost_cents: 9000)
    item.total_cost_cents = nil
    assert_nil item.margin_percent
  end

  test "margin_percent retorna nil cuando el costo es cero" do
    item = item_with_cost(price_cents: 18990, cost_cents: 9000)
    item.total_cost_cents = 0
    assert_nil item.margin_percent
  end

  test "margin_percent es negativo cuando se vende por debajo del costo" do
    item = item_with_cost(price_cents: 5000, cost_cents: 9000)
    assert item.margin_percent < 0
  end

  # ── Validaciones ──────────────────────────────────────────────────

  test "no es válido con cantidad cero" do
    item = item_with_cost(price_cents: 10000, cost_cents: 5000)
    item.quantity = 0
    assert_not item.valid?
  end

  test "unit_cost_cents y total_cost_cents pueden ser nil (productos sin lote FIFO)" do
    item = OrderItem.new(
      order:             orders(:orden_pagada),
      product:           products(:shampoo_wella),
      quantity:          1,
      unit_price_cents:  18990,
      total_price_cents: 18990
    )
    assert item.valid?
  end
end
