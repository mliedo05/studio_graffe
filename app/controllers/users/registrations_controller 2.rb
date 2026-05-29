# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # Cuando el email ya existe Y el usuario fue creado como walk-in por un supervisor,
  # en vez de mostrar "Email ya está en uso" redirigimos al formulario de recuperación
  # de contraseña con un mensaje amigable que explica la situación.
  def create
    email = params.dig(:user, :email).to_s.strip.downcase
    existing = User.find_by(email: email)

    if existing&.walk_in?
      redirect_to new_user_password_path,
                  notice: "Ya tienes una cuenta en Studio Graffé creada en salón. " \
                          "Ingresa tu email para crear tu contraseña y acceder."
      return
    end

    super
  end
end
