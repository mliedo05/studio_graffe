require "test_helper"

class AddressesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user    = users(:cliente)
    @address = addresses(:casa_cliente)
  end

  # ── Autenticación ────────────────────────────────────────────────

  test "POST /direcciones redirige a login si no autenticado" do
    post addresses_path, params: { address: valid_params }
    assert_redirected_to new_user_session_path
  end

  test "PATCH /direcciones/:id redirige a login si no autenticado" do
    patch address_path(@address), params: { address: { label: "Nueva" } }
    assert_redirected_to new_user_session_path
  end

  test "DELETE /direcciones/:id redirige a login si no autenticado" do
    delete address_path(@address)
    assert_redirected_to new_user_session_path
  end

  # ── CREATE ───────────────────────────────────────────────────────

  test "POST /direcciones crea una nueva dirección" do
    sign_in_as @user
    assert_difference "Address.count", 1 do
      post addresses_path, params: { address: valid_params }
    end
  end

  test "POST /direcciones redirige al perfil con notice" do
    sign_in_as @user
    post addresses_path, params: { address: valid_params }
    assert_redirected_to profile_path
    assert_equal "Dirección guardada.", flash[:notice]
  end

  test "POST /direcciones con datos inválidos no crea dirección" do
    sign_in_as @user
    assert_no_difference "Address.count" do
      post addresses_path, params: { address: valid_params.merge(region: "Región Inexistente") }
    end
  end

  test "POST /direcciones JSON crea dirección y devuelve id y label" do
    sign_in_as @user
    post addresses_path, params: { address: valid_params }, as: :json
    assert_response :created
    body = JSON.parse(response.body)
    assert body.key?("id")
    assert body.key?("label")
  end

  test "POST /direcciones JSON con datos inválidos devuelve 422" do
    sign_in_as @user
    post addresses_path, params: { address: valid_params.merge(region: "Inválida") }, as: :json
    assert_response :unprocessable_entity
  end

  # ── UPDATE ───────────────────────────────────────────────────────

  test "PATCH /direcciones/:id actualiza la dirección" do
    sign_in_as @user
    patch address_path(@address), params: { address: { label: "Mi nuevo label" } }
    assert_equal "Mi nuevo label", @address.reload.label
  end

  test "PATCH /direcciones/:id redirige al perfil con notice" do
    sign_in_as @user
    patch address_path(@address), params: { address: { label: "Actualizada" } }
    assert_redirected_to profile_path
    assert_equal "Dirección actualizada.", flash[:notice]
  end

  test "PATCH /direcciones/:id no puede editar dirección de otro usuario" do
    otro_usuario = users(:admin)
    sign_in_as otro_usuario
    original_label = @address.label
    patch address_path(@address), params: { address: { label: "Hackeado" } }
    assert_equal original_label, @address.reload.label
  end

  # ── DESTROY ──────────────────────────────────────────────────────

  test "DELETE /direcciones/:id elimina la dirección" do
    sign_in_as @user
    assert_difference "Address.count", -1 do
      delete address_path(@address)
    end
  end

  test "DELETE /direcciones/:id redirige al perfil con notice" do
    sign_in_as @user
    delete address_path(@address)
    assert_redirected_to profile_path
    assert_equal "Dirección eliminada.", flash[:notice]
  end

  test "DELETE /direcciones/:id no puede eliminar dirección de otro usuario" do
    otro_usuario = users(:admin)
    sign_in_as otro_usuario
    assert_no_difference "Address.count" do
      delete address_path(@address)
    end
  end

  # ── SET DEFAULT ──────────────────────────────────────────────────

  test "PATCH set_default marca la dirección como predeterminada" do
    sign_in_as @user
    secondary = addresses(:trabajo_cliente)
    refute secondary.default?

    patch set_default_address_path(secondary)
    assert secondary.reload.default?
  end

  test "PATCH set_default redirige al perfil con notice" do
    sign_in_as @user
    patch set_default_address_path(addresses(:trabajo_cliente))
    assert_redirected_to profile_path
    assert_equal "Dirección predeterminada actualizada.", flash[:notice]
  end

  private

  def valid_params
    {
      label:          "Mi casa",
      recipient_name: "María González",
      phone:          "+56 9 1234 5678",
      region:         "Metropolitana",
      comuna:         "Providencia",
      city:           "Santiago",
      street:         "Av. Providencia",
      street_number:  "100"
    }
  end
end
