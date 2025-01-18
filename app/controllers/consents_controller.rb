class ConsentsController < ApplicationController
  def new
    @consent = Consent.new
  end

  def index
    @consent_form2 = Consent.last
    @consent_form = Consent.new
  end

  def consentimiento
  end

  def create
    byebug
    service = Consents::Create.new(consent_params).call 
    if service[:success]
      
      redirect_to consents_path 
    else
      @consent = Consent.new
    flash[:danger] = service[:errors].join(', ')
    render :new, status: :unprocessable_entity
    end
  end

  private

  def set_consent
    @consent = Consent.find(params[:id])
  end

  def consent_params
    params.require(:consent).permit(:first_name, :last_name, :email, :document_type, :document_number, :phone_number, :professional_diagnosis, :professional_observations, :procedure_authorization, :procedure_acknowledgement, :diagnosis_confirmation, :image_use_authorization, :service_cost_acceptance, :informed_consent_acceptance, :is_adult, :signature)
  end
end
