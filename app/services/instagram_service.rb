require "net/http"
require "json"
require "uri"

class InstagramService
  CACHE_KEY = "instagram_feed_v3"
  CACHE_TTL = 1.hour
  FIELDS    = "id,caption,media_type,media_url,thumbnail_url,permalink,timestamp"
  IG_USER_ID = "17841404836391320"

  def self.fetch_posts(limit: 9)
    new.fetch_posts(limit: limit)
  end

  def fetch_posts(limit: 9)
    posts = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      result = fetch_from_api(limit: limit)
      result.any? ? result : nil   # no cachear vacío
    end
    posts || []
  rescue => e
    Rails.logger.error "[InstagramService] Error: #{e.class} — #{e.message}"
    []
  end

  private

  def fetch_from_api(limit:)
    token = Rails.application.credentials.dig(:instagram, :access_token) ||
            ENV["INSTAGRAM_ACCESS_TOKEN"]

    return [] if token.blank?

    url = "https://graph.facebook.com/v25.0/#{IG_USER_ID}/media" \
          "?fields=#{FIELDS}&limit=#{limit}&access_token=#{token}"

    uri  = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = true
    http.open_timeout = 5
    http.read_timeout = 10

    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "[InstagramService] HTTP #{response.code}: #{response.body[0..200]}"
      return []
    end

    data = JSON.parse(response.body)
    data["data"] || []
  end
end
