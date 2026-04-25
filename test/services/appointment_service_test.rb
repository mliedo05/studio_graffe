require "test_helper"

class AppointmentServiceTest < ActiveSupport::TestCase
  def setup
    @client  = users(:cliente)
    @stylist = users(:valentina)
    @service = services(:corte_damas)
  end

  def valid_params(overrides = {})
    ActionController::Parameters.new({
      service_id: @service.id,
      stylist_id: @stylist.id,
      starts_at:  10.days.from_now.change(hour: 10, min: 0)
    }.merge(overrides)).permit(:service_id, :stylist_id, :starts_at, :notes)
  end

  # ── list_for ──────────────────────────────────────────────────────
  test "list_for devuelve citas del usuario" do
    appointments = AppointmentService.list_for(@client)
    assert appointments.all? { |a| a.client_id == @client.id }
  end

  # ── form_data ─────────────────────────────────────────────────────
  test "form_data devuelve servicios agrupados por categoría" do
    data = AppointmentService.form_data
    assert data[:services].is_a?(Hash)
    assert data[:services].values.all? { |v| v.is_a?(Array) }
  end

  test "form_data devuelve solo estilistas" do
    data = AppointmentService.form_data
    assert data[:stylists].all?(&:stylist?)
  end

  # ── create — éxito ────────────────────────────────────────────────
  test "create con parámetros válidos devuelve success?" do
    result = AppointmentService.create(user: @client, params: valid_params)
    assert result.success?
    assert_equal @client, result.appointment.client
    assert_equal @service.price_cents, result.appointment.price_cents
    assert_empty result.errors
  end

  # ── create — fallos por validación ───────────────────────────────
  test "create sin starts_at devuelve errores" do
    result = AppointmentService.create(user: @client, params: valid_params(starts_at: nil))
    assert_not result.success?
    assert_not_empty result.errors
  end

  test "create con fecha en el pasado devuelve error" do
    result = AppointmentService.create(user: @client, params: valid_params(starts_at: 1.hour.ago))
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("futuro") }
  end

  test "create con estilista que no es stylist devuelve error" do
    result = AppointmentService.create(
      user: @client,
      params: valid_params(stylist_id: users(:admin).id)
    )
    assert_not result.success?
    assert result.errors.any? { |e| e.include?("estilista") }
  end

  # ── find_for ──────────────────────────────────────────────────────
  test "find_for devuelve cita del usuario" do
    apt = AppointmentService.find_for(user: @client, id: appointments(:cita_pendiente).id)
    assert_equal appointments(:cita_pendiente), apt
  end

  test "find_for lanza RecordNotFound para cita de otro usuario" do
    assert_raises(ActiveRecord::RecordNotFound) do
      AppointmentService.find_for(user: users(:admin), id: appointments(:cita_pendiente).id)
    end
  end

  # ── cancel ────────────────────────────────────────────────────────
  test "cancel cambia status a cancelled" do
    apt = AppointmentService.cancel(user: @client, id: appointments(:cita_pendiente).id)
    assert_equal "cancelled", apt.reload.status
  end

  test "cancel lanza InvalidTransitionError si la cita ya está cancelada" do
    assert_raises(Appointment::InvalidTransitionError) do
      AppointmentService.cancel(user: @client, id: appointments(:cita_cancelada).id)
    end
  end
end
