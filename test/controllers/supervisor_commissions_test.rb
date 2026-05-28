require "test_helper"

class SupervisorCommissionsTest < ActionDispatch::IntegrationTest
  test "usuario no autenticado es redirigido al login" do
    get supervisor_commissions_path
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede ver comisiones" do
    sign_in_as(users(:cliente))
    get supervisor_commissions_path
    assert_redirected_to root_path
  end

  test "admin accede a comisiones" do
    sign_in_as(users(:admin))
    get supervisor_commissions_path
    assert_response :success
  end

  test "comisiones responde con período today" do
    sign_in_as(users(:admin))
    get supervisor_commissions_path(period: "today")
    assert_response :success
  end

  test "comisiones con rango personalizado" do
    sign_in_as(users(:admin))
    get supervisor_commissions_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    assert_response :success
  end

  test "comisiones filtra por estilista" do
    sign_in_as(users(:admin))
    get supervisor_commissions_path(
      period:     "custom",
      from:       "2026-01-01",
      to:         "2026-01-31",
      stylist_id: users(:valentina).id
    )
    assert_response :success
    assert_match users(:valentina).first_name, response.body
  end

  test "comisiones muestra gráfico y resumen por estilista" do
    sign_in_as(users(:admin))
    get supervisor_commissions_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    assert_select "h3", text: /Comisiones por estilista/i
  end
end
