require "test_helper"

class SupervisorClientsControllerTest < ActionDispatch::IntegrationTest
  # ── Acceso ────────────────────────────────────────────────────────

  test "usuario no autenticado es redirigido al login" do
    get supervisor_clients_path
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede acceder a la lista de clientes" do
    sign_in_as(users(:cliente))
    get supervisor_clients_path
    assert_redirected_to root_path
  end

  test "estilista no puede acceder a la lista de clientes" do
    sign_in_as(users(:valentina))
    get supervisor_clients_path
    assert_redirected_to root_path
  end

  test "supervisor puede acceder a la lista de clientes" do
    sign_in_as(users(:supervisor))
    get supervisor_clients_path
    assert_response :success
  end

  test "admin puede acceder a la lista de clientes" do
    sign_in_as(users(:admin))
    get supervisor_clients_path
    assert_response :success
  end

  # ── Index ─────────────────────────────────────────────────────────

  test "index muestra clientas registradas" do
    sign_in_as(users(:admin))
    get supervisor_clients_path
    assert_response :success
    assert_select "table"
    assert_match users(:cliente).full_name, response.body
  end

  test "index no muestra estilistas ni admins en la tabla de clientes" do
    sign_in_as(users(:admin))
    get supervisor_clients_path
    # La tabla solo debe tener filas de clientes; buscamos que los emails de no-clientes no aparezcan
    assert_no_match users(:valentina).email, response.body
    assert_no_match users(:supervisor).email, response.body
  end

  test "index filtra por nombre con parámetro q" do
    sign_in_as(users(:admin))
    get supervisor_clients_path(q: users(:cliente).first_name)
    assert_response :success
    assert_match users(:cliente).full_name, response.body
  end

  test "index con búsqueda sin resultados muestra mensaje vacío" do
    sign_in_as(users(:admin))
    get supervisor_clients_path(q: "zzz_no_existe_zzz")
    assert_response :success
    assert_match "Sin resultados", response.body
  end

  # ── Show ──────────────────────────────────────────────────────────

  test "show devuelve 200 para cliente existente" do
    sign_in_as(users(:admin))
    get supervisor_client_path(users(:cliente))
    assert_response :success
  end

  test "show muestra nombre e email del cliente" do
    sign_in_as(users(:admin))
    get supervisor_client_path(users(:cliente))
    assert_match users(:cliente).full_name, response.body
    assert_match users(:cliente).email,     response.body
  end

  test "show muestra historial de atenciones" do
    sign_in_as(users(:admin))
    get supervisor_client_path(users(:cliente))
    assert_select "h3", text: /Atenciones/i
  end

  test "show muestra historial de compras" do
    sign_in_as(users(:admin))
    get supervisor_client_path(users(:cliente))
    assert_select "h3", text: /Compras online/i
  end

  test "show devuelve 404 para id que no es cliente" do
    sign_in_as(users(:admin))
    get supervisor_client_path(users(:valentina))
    assert_response :not_found
  end
end
