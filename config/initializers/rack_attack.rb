# Límite de intentos para frenar ataques de fuerza bruta y abuso.
# Usa Rails.cache (Solid Cache en producción).
class Rack::Attack
  # Ingreso: 5 intentos cada 20 segundos por IP y 20 por hora por email.
  throttle("login/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.post? && req.path == "/cuenta/ingresar"
  end

  throttle("login/email", limit: 20, period: 1.hour) do |req|
    if req.post? && req.path == "/cuenta/ingresar"
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  # Registro y recuperación de contraseña: 5 por hora por IP.
  throttle("cuenta/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && (req.path == "/cuenta" || req.path.start_with?("/cuenta/password"))
  end

  # Pago y webhook de Getnet: límites holgados para no afectar clientes reales.
  throttle("checkout/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.post? && req.path.start_with?("/checkout")
  end

  throttle("getnet/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/getnet")
  end

  # Límite general: 300 peticiones cada 5 minutos por IP (sin contar assets).
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/up")
  end

  self.throttled_responder = lambda do |_request|
    [ 429, { "content-type" => "text/plain; charset=utf-8" }, [ "Demasiados intentos. Espera un momento y vuelve a intentarlo.\n" ] ]
  end
end

Rack::Attack.enabled = !Rails.env.test?
