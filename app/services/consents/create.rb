class Consents::Create
  def initialize(params)
    @params = params
  end

  def call
    consent = Consent.new(@params)

    if consent.save
      { success: true, message: "consent create succefully.", data: consent }
    else
      { success: false, errors: consent.errors.full_messages }
    end
  end
end
