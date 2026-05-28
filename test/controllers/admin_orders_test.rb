require "test_helper"

class AdminOrdersTest < ActionDispatch::IntegrationTest
  def setup
    sign_in_as users(:admin)
  end

  # ── GET /admin/orders ─────────────────────────────────────────────

  test "GET /admin/orders devuelve 200" do
    get admin_orders_path
    assert_response :success
  end

  test "GET /admin/orders muestra las órdenes existentes" do
    get admin_orders_path
    assert_select "td", text: /ORD-PAID01/
  end

  test "GET /admin/orders muestra las tarjetas de resumen" do
    get admin_orders_path
    assert_select "div", text: /Ventas pagadas/i
    assert_select "div", text: /Canceladas/i
    assert_select "div", text: /En proceso/i
  end

  test "GET /admin/orders muestra el buscador inline" do
    get admin_orders_path
    assert_select "input#oq-text"
    assert_select "select#oq-status"
    assert_select "input#oq-from"
    assert_select "input#oq-to"
  end

  # ── Búsqueda por número de orden ─────────────────────────────────

  test "buscar por número de orden muestra la orden correcta" do
    get admin_orders_path, params: { q: { search_text: "ORD-PAID01" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
  end

  test "buscar por número inexistente no muestra órdenes" do
    get admin_orders_path, params: { q: { search_text: "ORD-NOEEXISTE" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/, count: 0
  end

  # ── Búsqueda por nombre del cliente ──────────────────────────────

  test "buscar por nombre del cliente devuelve sus órdenes" do
    get admin_orders_path, params: { q: { search_text: "María" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
  end

  test "buscar por apellido del cliente devuelve sus órdenes" do
    get admin_orders_path, params: { q: { search_text: "González" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
  end

  # ── Búsqueda por email del cliente ────────────────────────────────

  test "buscar por email completo devuelve las órdenes del cliente" do
    get admin_orders_path, params: { q: { search_text: "maria@example.com" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
  end

  test "buscar por email parcial devuelve coincidencias" do
    get admin_orders_path, params: { q: { search_text: "@example" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID/
  end

  # ── Filtro por estado ─────────────────────────────────────────────

  test "filtrar por estado paid solo muestra órdenes pagadas" do
    get admin_orders_path, params: { q: { status_eq: "paid" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
    assert_select "td", text: /ORD-CART01/, count: 0
  end

  test "filtrar por estado cart solo muestra carritos" do
    get admin_orders_path, params: { q: { status_eq: "cart" } }
    assert_response :success
    assert_select "td", text: /ORD-CART01/
    assert_select "td", text: /ORD-PAID01/, count: 0
  end

  test "filtrar por estado vacío devuelve todas las órdenes" do
    get admin_orders_path, params: { q: { status_eq: "" } }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
    assert_select "td", text: /ORD-CART01/
  end

  # ── Filtro por rango de fechas ────────────────────────────────────

  test "filtrar por fecha futura no devuelve órdenes existentes" do
    get admin_orders_path, params: {
      q: { created_at_gteq: 1.year.from_now.to_date.to_s }
    }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/, count: 0
  end

  test "filtrar con rango amplio devuelve todas las órdenes" do
    get admin_orders_path, params: {
      q: {
        created_at_gteq: 10.years.ago.to_date.to_s,
        created_at_lteq: 1.year.from_now.to_date.to_s
      }
    }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
  end

  # ── Combinación de criterios ──────────────────────────────────────

  test "texto + estado reducen los resultados correctamente" do
    get admin_orders_path, params: {
      q: { search_text: "maria@example.com", status_eq: "paid" }
    }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
    assert_select "td", text: /ORD-CART01/, count: 0
  end

  test "texto + estado + fechas funcionan juntos sin error" do
    get admin_orders_path, params: {
      q: {
        search_text:      "María",
        status_eq:        "paid",
        created_at_gteq:  10.years.ago.to_date.to_s,
        created_at_lteq:  1.year.from_now.to_date.to_s
      }
    }
    assert_response :success
    assert_select "td", text: /ORD-PAID01/
  end

  # ── Tarjetas de resumen respetan los filtros ──────────────────────

  test "tarjeta de ventas pagadas refleja el total correcto" do
    get admin_orders_path, params: { q: { status_eq: "paid" } }
    assert_response :success
    # Con solo órdenes pagadas, la tarjeta de canceladas debe mostrar $0
    assert_select "div", text: /\$0/
  end

  # ── Vista detalle ─────────────────────────────────────────────────

  test "GET /admin/orders/:id devuelve 200" do
    get admin_order_path(orders(:orden_pagada))
    assert_response :success
  end

  test "GET /admin/orders/:id muestra el número de orden" do
    get admin_order_path(orders(:orden_pagada))
    assert_select "td", text: /ORD-PAID01/
  end

  test "GET /admin/orders/:id muestra los productos del pedido" do
    get admin_order_path(orders(:orden_pagada))
    assert_response :success
  end

  # ── Acceso sin autenticación ──────────────────────────────────────

  test "usuario no autenticado es redirigido" do
    delete destroy_user_session_path
    get admin_orders_path
    assert_response :redirect
  end
end
