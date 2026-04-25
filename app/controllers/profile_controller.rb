class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @upcoming_appointments = current_user.appointments_as_client.upcoming.active.includes(:service, :stylist).limit(5)
    @past_appointments     = current_user.appointments_as_client.past.includes(:service, :stylist).limit(10)
    @orders                = current_user.orders.where.not(status: "cart").order(created_at: :desc).includes(order_items: :product).limit(10)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update_with_password(user_params)
      bypass_sign_in(@user)
      redirect_to profile_path, notice: "Perfil actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email,
                                  :password, :password_confirmation, :current_password)
  end
end
