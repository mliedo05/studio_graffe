require "test_helper"

# Tests para el scope Order.search_text
# Cubre búsqueda por número de orden, nombre, apellido y email de cliente.
class OrderSearchTest < ActiveSupport::TestCase
  # ── search_text: número de orden ─────────────────────────────────

  test "search_text encuentra orden por número exacto" do
    results = Order.search_text("ORD-PAID01")
    assert_includes results, orders(:orden_pagada)
  end

  test "search_text encuentra orden por número parcial" do
    results = Order.search_text("PAID")
    assert_includes results, orders(:orden_pagada)
    assert_includes results, orders(:orden_pagada_delivery)
  end

  test "search_text es case-insensitive para número de orden" do
    results = Order.search_text("ord-paid01")
    assert_includes results, orders(:orden_pagada)
  end

  # ── search_text: nombre del cliente ──────────────────────────────

  test "search_text encuentra orden por primer nombre del cliente" do
    results = Order.search_text("María")
    assert_includes results, orders(:orden_pagada)
  end

  test "search_text encuentra orden por apellido del cliente" do
    results = Order.search_text("González")
    assert_includes results, orders(:orden_pagada)
  end

  test "search_text es case-insensitive para nombre" do
    results = Order.search_text("maría")
    assert_includes results, orders(:orden_pagada)
  end

  test "search_text encuentra por nombre parcial" do
    results = Order.search_text("onzá")
    assert_includes results, orders(:orden_pagada)
  end

  # ── search_text: email del cliente ───────────────────────────────

  test "search_text encuentra orden por email completo" do
    results = Order.search_text("maria@example.com")
    assert_includes results, orders(:orden_pagada)
  end

  test "search_text encuentra orden por email parcial" do
    results = Order.search_text("@example")
    assert_includes results, orders(:orden_pagada)
    assert_includes results, orders(:orden_pagada_delivery)
  end

  # ── search_text: sin resultados ───────────────────────────────────

  test "search_text retorna vacío si no hay coincidencias" do
    results = Order.search_text("XYZ_NADA_999")
    assert_empty results
  end

  # ── search_text: query vacía devuelve todo ────────────────────────

  test "search_text con nil devuelve todas las órdenes" do
    total = Order.count
    assert_equal total, Order.search_text(nil).count
  end

  test "search_text con string vacío devuelve todas las órdenes" do
    total = Order.count
    assert_equal total, Order.search_text("").count
  end

  test "search_text con solo espacios devuelve todas las órdenes" do
    total = Order.count
    assert_equal total, Order.search_text("   ").count
  end

  # ── Combinación con status_eq (como lo usa Ransack) ──────────────

  test "search_text + status scope reduce resultados correctamente" do
    # Solo ordenes pagadas que coincidan con el email del cliente
    results = Order.search_text("maria@example.com").where(status: "paid")
    assert results.all? { |o| o.status == "paid" }
    assert results.all? { |o| o.user.email.include?("maria") }
  end

  test "search_text + rango de fechas reduce resultados" do
    future = 1.year.from_now
    results = Order.search_text("PAID").where(created_at: ..future)
    assert results.count >= 1
  end
end
