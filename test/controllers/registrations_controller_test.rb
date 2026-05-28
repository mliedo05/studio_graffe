require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  # ── Registro normal (cliente web nuevo) ──────────────────────────

  test "nuevo usuario puede registrarse" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          first_name: "Laura",
          last_name:  "Méndez",
          email:      "laura@example.com",
          password:   "password123",
          password_confirmation: "password123"
        }
      }, headers: { "HTTP_USER_AGENT" => MODERN_UA }
    end
  end

  # ── Email existente de usuario normal (no walk-in) ────────────────

  test "email duplicado de cliente normal muestra error estándar de Devise" do
    post user_registration_path, params: {
      user: {
        first_name: "Otra",
        last_name:  "Persona",
        email:      users(:cliente).email,
        password:   "password123",
        password_confirmation: "password123"
      }
    }, headers: { "HTTP_USER_AGENT" => MODERN_UA }

    # Devise renderiza el formulario con errores (no redirige a forgot-password)
    assert_response :unprocessable_entity
  end

  # ── Email existente de cliente walk-in ───────────────────────────

  test "email de cliente walk-in redirige a recuperar contraseña" do
    post user_registration_path, params: {
      user: {
        first_name: "Ana",
        last_name:  "Torres",
        email:      users(:cliente_walk_in).email,
        password:   "password123",
        password_confirmation: "password123"
      }
    }, headers: { "HTTP_USER_AGENT" => MODERN_UA }

    assert_redirected_to new_user_password_path
    assert_match "Studio Graffé", flash[:notice]
  end

  test "redirige a forgot-password sin crear nuevo usuario para walk-in" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          first_name: "Ana",
          last_name:  "Torres",
          email:      users(:cliente_walk_in).email,
          password:   "nueva123",
          password_confirmation: "nueva123"
        }
      }, headers: { "HTTP_USER_AGENT" => MODERN_UA }
    end
  end

  # ── walk_in? en el modelo ─────────────────────────────────────────

  test "walk_in? es true para clientes walk-in" do
    assert users(:cliente_walk_in).walk_in?
  end

  test "walk_in? es false para usuarios normales" do
    assert_not users(:cliente).walk_in?
    assert_not users(:admin).walk_in?
    assert_not users(:valentina).walk_in?
  end
end
