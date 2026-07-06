require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "usuario no autenticado es redirigido a login al acceder a /admin" do
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "usuario cliente es redirigido a login al intentar acceder a /admin" do
    sign_in_as(users(:cliente))
    get admin_root_path
    assert_redirected_to new_user_session_path
    assert_match "administrador", flash[:alert]
  end

  test "usuario stylist es redirigido a login al intentar acceder a /admin" do
    sign_in_as(users(:valentina))
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "usuario admin puede acceder a /admin" do
    sign_in_as(users(:admin))
    get admin_root_path
    assert_response :success
  end

  # ── Admin accede a rutas supervisor ──────────────────────────────
  # El admin tiene acceso total al panel supervisor porque
  # authenticate_supervisor! permite admin? || supervisor?

  test "admin puede acceder al dashboard supervisor" do
    sign_in_as(users(:admin))
    get supervisor_root_path
    assert_response :success
  end

  test "admin puede acceder a atenciones del supervisor" do
    sign_in_as(users(:admin))
    get supervisor_attendances_path
    assert_response :success
  end

  test "admin puede acceder a caja del supervisor" do
    sign_in_as(users(:admin))
    get supervisor_caja_path
    assert_response :success
  end

  test "admin puede acceder a comisiones del supervisor" do
    sign_in_as(users(:admin))
    get supervisor_commissions_path
    assert_response :success
  end

  test "admin puede acceder a ventas del supervisor" do
    sign_in_as(users(:admin))
    get supervisor_sales_path
    assert_response :success
  end

  test "supervisor_panel en ActiveAdmin redirige al panel supervisor" do
    sign_in_as(users(:admin))
    get admin_supervisor_path
    assert_redirected_to supervisor_root_path
  end

  test "admin puede acceder a la lista de clientes del supervisor" do
    sign_in_as(users(:admin))
    get supervisor_clients_path
    assert_response :success
  end

  test "admin puede ver historial de un cliente" do
    sign_in_as(users(:admin))
    get supervisor_client_path(users(:cliente))
    assert_response :success
  end
end
