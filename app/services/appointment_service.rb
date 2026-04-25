class AppointmentService
  Result = Data.define(:success?, :appointment, :errors)

  def self.list_for(user)
    user.appointments_as_client.includes(:service, :stylist).order(starts_at: :desc)
  end

  def self.form_data
    {
      services: Service.active.ordered.group_by(&:category),
      stylists: User.stylists.includes(:stylist_profile)
    }
  end

  def self.create(user:, params:)
    appointment = Appointment.new(params)
    appointment.client      = user
    appointment.price_cents = appointment.service&.price_cents || 0

    if appointment.save
      Result.new(success?: true, appointment: appointment, errors: [])
    else
      Result.new(success?: false, appointment: appointment, errors: appointment.errors.full_messages)
    end
  end

  def self.find_for(user:, id:)
    user.appointments_as_client.find(id)
  end

  def self.cancel(user:, id:)
    appointment = find_for(user: user, id: id)
    # Delega la validación de estado al modelo — lanza InvalidTransitionError si no se puede cancelar
    appointment.cancel!
    appointment
  end
end
