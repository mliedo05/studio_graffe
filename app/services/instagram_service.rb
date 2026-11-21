require "net/http"
require "json"
require "uri"

# Feed de Instagram para la portada.
#
# - CACHE_KEY: copia "fresca" (1 hora).
# - BACKUP_KEY: última respuesta buena, sin vencimiento. Si Instagram falla
#   (token vencido, caída de Meta), se siguen mostrando esas publicaciones
#   en vez de las fotos de relleno.
# - InstagramRefreshJob la refresca cada hora en producción y avisa por
#   correo si el token deja de funcionar.
class InstagramService
  CACHE_KEY  = "instagram_feed_v3"
  BACKUP_KEY = "instagram_feed_backup_v1"
  CACHE_TTL  = 1.hour
  FIELDS     = "id,caption,media_type,media_url,thumbnail_url,permalink,timestamp"
  IG_USER_ID = "17841404836391320"

  class FetchError < StandardError; end

  def self.fetch_posts(limit: 9)
    new.fetch_posts(limit: limit)
  end

  # Para la vista: nunca lanza error. Fresca → respaldo → [].
  def fetch_posts(limit: 9)
    posts = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      result = fetch_from_api(limit: limit)
      Rails.cache.write(BACKUP_KEY, result) if result.any?
      result.any? ? result : nil # no cachear vacío
    end
    posts.presence || backup_posts
  rescue => e
    Rails.logger.error "[InstagramService] Error: #{e.class} — #{e.message}"
    backup_posts
  end

  # Para el job: fuerza la consulta y lanza FetchError si algo falla.
  def refresh!(limit: 9)
    result = fetch_from_api(limit: limit, raise_errors: true)
    raise FetchError, "Instagram devolvió 0 publicaciones" if result.empty?

    Rails.cache.write(CACHE_KEY, result, expires_in: CACHE_TTL)
    Rails.cache.write(BACKUP_KEY, result)
    result
  end

  private

  def backup_posts
    Rails.cache.read(BACKUP_KEY) || []
  rescue => e
    Rails.logger.error "[InstagramService] Error leyendo respaldo: #{e.message}"
    []
  end

  def token
    Rails.application.credentials.dig(:instagram, :access_token) || ENV["INSTAGRAM_ACCESS_TOKEN"]
  end

  def fetch_from_api(limit:, raise_errors: false)
    if token.blank?
      raise FetchError, "No hay token de Instagram configurado" if raise_errors
      return []
    end

    uri = URI("https://graph.facebook.com/v25.0/#{IG_USER_ID}/media")
    uri.query = URI.encode_www_form(fields: FIELDS, limit: limit, access_token: token)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = true
    http.open_timeout = 5
    http.read_timeout = 10

    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      message = "HTTP #{response.code}: #{response.body.to_s[0..200]}"
      Rails.logger.error "[InstagramService] #{message}"
      raise FetchError, message if raise_errors
      return []
    end

    JSON.parse(response.body)["data"] || []
  rescue FetchError
    raise
  rescue => e
    raise FetchError, "#{e.class}: #{e.message}" if raise_errors
    raise
  end
end
