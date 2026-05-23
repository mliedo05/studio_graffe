require "digest"
require "base64"
require "net/http"
require "json"

# Getnet Web Checkout API integration
# Docs: Manual de Integración vía API Web Checkout v2.4
class GetnetService
  SANDBOX_URL    = "https://checkout.test.getnet.cl"
  PRODUCTION_URL = "https://checkout.getnet.cl"

  def initialize
    credentials = Rails.application.credentials.dig(:getnet) || {}
    @login      = credentials[:login]      || ENV.fetch("GETNET_LOGIN",      "7ffbb7bf1f7361b1200b2e8d74e1d76f")
    @secret_key = credentials[:secret_key] || ENV.fetch("GETNET_SECRET_KEY", "SnZP3D63n3I9dH9O")
    @base_url   = Rails.env.production? ? PRODUCTION_URL : SANDBOX_URL
  end

  # Creates a Getnet checkout session and returns the processUrl.
  # Returns { request_id:, process_url: } on success, raises GetnetError on failure.
  def create_transaction(order, ip_address:, user_agent:, return_url:, cancel_url:)
    payload = {
      locale:     "es_CL",
      buyer: {
        name:         order.billing_first_name,
        surname:      order.billing_last_name,
        email:        order.billing_email,
        document:     order.billing_document_number,
        documentType: "CLRUT",
        mobile:       order.billing_phone
      },
      payment: {
        reference:  order.number,
        description: "Compra Studio Graffe #{order.number}",
        amount: {
          currency: "CLP",
          total:    order.total.fractional.to_i
        }
      },
      expiration: (Time.current + 15.minutes).iso8601,
      ipAddress:  ip_address,
      userAgent:  user_agent,
      returnUrl:  return_url,
      cancelUrl:  cancel_url,
      skipResult: true
    }

    response = post("/api/session/", payload)

    unless response["status"]&.fetch("status", nil) == "OK"
      msg = response.dig("status", "message") || "Error desconocido"
      raise GetnetError, "Getnet rechazó la sesión: #{msg}"
    end

    {
      request_id:  response["requestId"].to_s,
      process_url: response["processUrl"]
    }
  end

  # Queries the status of a transaction by requestId.
  # Returns the full response hash from Getnet.
  def get_transaction_info(request_id)
    post("/api/session/#{request_id}", {})
  end

  # Returns true if the transaction is approved.
  def approved?(request_id)
    info = get_transaction_info(request_id)
    info.dig("status", "status") == "APPROVED"
  end

  private

  # Builds the auth object per Getnet spec:
  # tranKey = Base64(SHA-256(nonce_raw + seed + secret_key))
  def auth
    nonce_raw = SecureRandom.hex(16)
    seed      = Time.current.iso8601
    tran_key  = Base64.strict_encode64(
      Digest::SHA256.digest(nonce_raw + seed + @secret_key)
    )
    {
      login:    @login,
      tranKey:  tran_key,
      nonce:    Base64.strict_encode64(nonce_raw),
      seed:     seed
    }
  end

  def post(path, body)
    uri  = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.verify_mode = Rails.env.development? ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
    request.body = body.merge(auth: auth).to_json

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    raise GetnetError, "Error de conexión con Getnet: #{e.message}"
  end

  class GetnetError < StandardError; end
end
