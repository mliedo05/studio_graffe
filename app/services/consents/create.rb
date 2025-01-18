class Consents::Create
  def initialize(params)
    @params = params
  end

  def call
    consent = Consent.new(@params.except(:signature))

    if @params[:signature].present?
      decoded_signature = decode_base64(@params[:signature])
      consent.signature.attach(io: StringIO.new(decoded_signature), filename: "signature.png", content_type: "image/png")
    end

    if consent.save
      { success: true, message: "Consent created successfully.", data: consent }
    else
      { success: false, errors: consent.errors.full_messages }
    end
  end

  private

  def decode_base64(base64_string)
    match = base64_string.match(/^data:image\/(.+);base64,(.*)$/)
    if match
      Base64.decode64(match[2])
    else
      nil
    end
  end
end
