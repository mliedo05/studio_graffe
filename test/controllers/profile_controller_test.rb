require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:cliente)
  end

  # ── show ─────────────────────────────────────────────────────────

  test "GET /perfil redirige a login cuando no autenticado" do
    get profile_path
    assert_redirected_to new_user_session_path
  end

  test "GET /perfil devuelve 200 cuando autenticado" do
    sign_in_as(@user)
    get profile_path
    assert_response :success
  end

  test "GET /perfil muestra nombre del usuario" do
    sign_in_as(@user)
    get profile_path
    assert_match @user.first_name, response.body
  end

  test "GET /perfil muestra las direcciones guardadas del usuario" do
    sign_in_as(@user)
    get profile_path
    assert_match addresses(:casa_cliente).label,    response.body
    assert_match addresses(:trabajo_cliente).label, response.body
  end

  test "GET /perfil muestra sección de historial de compras" do
    sign_in_as(@user)
    get profile_path
    assert_match "Historial de compras", response.body
  end

  test "GET /perfil muestra sección de direcciones guardadas" do
    sign_in_as(@user)
    get profile_path
    assert_match "Direcciones guardadas", response.body
  end

  test "GET /perfil muestra método de pago en órdenes pagadas" do
    sign_in_as(@user)
    order = orders(:orden_pagada)
    get profile_path
    assert_match order.number, response.body
  end

  # ── edit ─────────────────────────────────────────────────────────

  test "GET /perfil/editar redirige a login cuando no autenticado" do
    get edit_profile_path
    assert_redirected_to new_user_session_path
  end

  test "GET /perfil/editar devuelve 200 cuando autenticado" do
    sign_in_as(@user)
    get edit_profile_path
    assert_response :success
  end

  # ── update ───────────────────────────────────────────────────────

  test "PATCH /perfil redirige a login cuando no autenticado" do
    patch perfil_path, params: { user: { first_name: "Nueva" } }
    assert_redirected_to new_user_session_path
  end

  test "PATCH /perfil con current_password correcto actualiza perfil" do
    sign_in_as(@user)
    patch perfil_path, params: {
      user: {
        first_name:       "Actualizada",
        last_name:        @user.last_name,
        email:            @user.email,
        current_password: "graffe2025!"
      }
    }
    assert_redirected_to profile_path
    assert_match "Perfil actualizado", flash[:notice]
    assert_equal "Actualizada", @user.reload.first_name
  end

  test "PATCH /perfil actualiza el teléfono del usuario" do
    sign_in_as(@user)
    patch perfil_path, params: {
      user: {
        first_name:       @user.first_name,
        last_name:        @user.last_name,
        email:            @user.email,
        phone:            "+56 9 9999 8888",
        current_password: "graffe2025!"
      }
    }
    assert_equal "+56 9 9999 8888", @user.reload.phone
  end

  test "PATCH /perfil con current_password incorrecto renderiza edit con 422" do
    sign_in_as(@user)
    patch perfil_path, params: {
      user: {
        first_name:       "Fail",
        email:            @user.email,
        current_password: "contrasena_incorrecta"
      }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH /perfil sin current_password renderiza edit con 422" do
    sign_in_as(@user)
    patch perfil_path, params: {
      user: {
        first_name:       "Fail",
        email:            @user.email,
        current_password: ""
      }
    }
    assert_response :unprocessable_entity
  end
end
