require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:cliente)
  end

  # --- show ---

  test "GET /perfil redirige a login cuando no autenticado" do
    get profile_path
    assert_redirected_to new_user_session_path
  end

  test "GET /perfil devuelve 200 cuando autenticado" do
    sign_in_as(@user)
    get profile_path
    assert_response :success
  end

  # --- edit ---

  test "GET /perfil/editar redirige a login cuando no autenticado" do
    get edit_profile_path
    assert_redirected_to new_user_session_path
  end

  test "GET /perfil/editar devuelve 200 cuando autenticado" do
    sign_in_as(@user)
    get edit_profile_path
    assert_response :success
  end

  # --- update ---

  test "PATCH /perfil redirige a login cuando no autenticado" do
    patch perfil_path, params: { user: { first_name: "Nueva" } }
    assert_redirected_to new_user_session_path
  end

  test "PATCH /perfil con current_password correcto actualiza perfil y redirige" do
    sign_in_as(@user)
    patch perfil_path, params: {
      user: {
        first_name: "Actualizada",
        last_name: @user.last_name,
        email: @user.email,
        current_password: "graffe2025!"
      }
    }
    assert_redirected_to profile_path
    follow_redirect!
    assert_match "Perfil actualizado", response.body
    assert_equal "Actualizada", @user.reload.first_name
  end

  test "PATCH /perfil con current_password incorrecto renderiza edit con 422" do
    sign_in_as(@user)
    patch perfil_path, params: {
      user: {
        first_name: "Fail",
        email: @user.email,
        current_password: "contrasena_incorrecta"
      }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH /perfil sin current_password renderiza edit con 422" do
    sign_in_as(@user)
    patch perfil_path, params: {
      user: {
        first_name: "Fail",
        email: @user.email,
        current_password: ""
      }
    }
    assert_response :unprocessable_entity
  end
end
