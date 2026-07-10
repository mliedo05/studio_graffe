require "test_helper"

class SupervisorDashboardTest < ActionDispatch::IntegrationTest
  # ── Acceso ────────────────────────────────────────────────────────

  test "usuario no autenticado es redirigido al login" do
    get supervisor_root_path
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede ver el dashboard" do
    sign_in_as(users(:cliente))
    get supervisor_root_path
    assert_redirected_to root_path
  end

  test "admin accede al dashboard" do
    sign_in_as(users(:admin))
    get supervisor_root_path
    assert_response :success
  end

  # ── Períodos ──────────────────────────────────────────────────────

  test "dashboard responde con período today" do
    sign_in_as(users(:admin))
    get supervisor_root_path(period: "today")
    assert_response :success
  end

  test "dashboard responde con período week" do
    sign_in_as(users(:admin))
    get supervisor_root_path(period: "week")
    assert_response :success
  end

  test "dashboard responde con período month" do
    sign_in_as(users(:admin))
    get supervisor_root_path(period: "month")
    assert_response :success
  end

  test "dashboard responde con rango personalizado" do
    sign_in_as(users(:admin))
    get supervisor_root_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    assert_response :success
  end

  # ── Contenido ─────────────────────────────────────────────────────

  test "dashboard muestra resumen mensual acumulado" do
    sign_in_as(users(:admin))
    get supervisor_root_path
    assert_select "h3", text: /Resumen mensual acumulado/i
  end

  test "dashboard muestra KPI cards" do
    sign_in_as(users(:admin))
    get supervisor_root_path
    assert_select ".sv-card-label", text: /Ventas totales/i
    assert_select ".sv-card-label", text: /Total comisiones/i
    assert_select ".sv-card-label", text: /Atenciones/i
    assert_select ".sv-card-label", text: /Stock crítico/i
  end

  test "dashboard muestra sección últimas atenciones" do
    sign_in_as(users(:admin))
    get supervisor_root_path
    assert_select "h3", text: /Últimas atenciones/i
  end

  test "dashboard no falla con resumen mensual vacío" do
    sign_in_as(users(:admin))
    # Rango donde no hay datos
    get supervisor_root_path(period: "custom", from: "2000-01-01", to: "2000-01-31")
    assert_response :success
    assert_match "Sin registros", response.body
  end

  # ── Modal stock crítico ───────────────────────────────────────────

  test "dashboard muestra tarjeta de stock crítico con conteo correcto" do
    sign_in_as(users(:admin))
    get supervisor_root_path
    expected = Product.active.where("stock_quantity <= 3").count.to_s
    assert_select ".sv-card-label", text: /Stock crítico/i
    assert_match expected, response.body
  end

  test "dashboard incluye modal de stock crítico cuando hay productos con stock bajo" do
    Product.active.where("stock_quantity <= 3").tap do |critical|
      if critical.any?
        sign_in_as(users(:admin))
        get supervisor_root_path
        assert_select "#stock-modal"
        assert_select "#stock-card"
      end
    end
  end

  test "dashboard no incluye modal si no hay stock crítico" do
    Product.update_all(stock_quantity: 10)
    sign_in_as(users(:admin))
    get supervisor_root_path
    assert_select "#stock-modal", count: 0
  end

  # ── Clientes accesibles desde el sidebar ─────────────────────────

  test "dashboard incluye enlace a clientes en la navegación" do
    sign_in_as(users(:admin))
    get supervisor_root_path
    assert_select "a[href='#{supervisor_clients_path}']"
  end
end
