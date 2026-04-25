class AppointmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @appointments = AppointmentService.list_for(current_user)
  end

  def new
    @appointment = Appointment.new
    @services, @stylists = AppointmentService.form_data.values_at(:services, :stylists)
  end

  def create
    result = AppointmentService.create(user: current_user, params: appointment_params)

    if result.success?
      redirect_to appointments_path, notice: "Cita agendada exitosamente. Te confirmaremos pronto."
    else
      @appointment = result.appointment
      @services, @stylists = AppointmentService.form_data.values_at(:services, :stylists)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @appointment = AppointmentService.find_for(user: current_user, id: params[:id])
  end

  def cancel
    AppointmentService.cancel(user: current_user, id: params[:id])
    redirect_to appointments_path, notice: "Cita cancelada."
  rescue Appointment::InvalidTransitionError => e
    redirect_to appointments_path, alert: e.message
  end

  private

  def appointment_params
    params.require(:appointment).permit(:service_id, :stylist_id, :starts_at, :notes)
  end
end
