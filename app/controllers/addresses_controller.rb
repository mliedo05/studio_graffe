class AddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_address, only: [ :update, :destroy, :set_default ]

  def create
    @address = current_user.addresses.build(address_params)
    if @address.save
      respond_to do |f|
        f.html { redirect_back fallback_location: profile_path, notice: "Dirección guardada." }
        f.json { render json: { id: @address.id, label: @address.label }, status: :created }
      end
    else
      respond_to do |f|
        f.html { redirect_back fallback_location: profile_path, alert: @address.errors.full_messages.first }
        f.json { render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @address.update(address_params)
      redirect_back fallback_location: profile_path, notice: "Dirección actualizada."
    else
      redirect_back fallback_location: profile_path, alert: @address.errors.full_messages.first
    end
  end

  def destroy
    @address.destroy
    redirect_back fallback_location: profile_path, notice: "Dirección eliminada."
  end

  def set_default
    @address.update!(default: true)
    redirect_back fallback_location: profile_path, notice: "Dirección predeterminada actualizada."
  end

  private

  def load_address
    @address = current_user.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(
      :label, :recipient_name, :phone,
      :region, :comuna, :city,
      :street, :street_number, :apartment,
      :default
    )
  end
end
