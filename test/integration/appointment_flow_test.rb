require "test_helper"

# Prueba el flujo completo de agenda de citas
class AppointmentFlowTest < ActionDispatch::IntegrationTest
  def setup
    @cliente   = users(:cliente)
    @stylist   = users(:valentina)
    @service   = services(:corte_damas)
    sign_in_as @cliente
  end

  test "cliente puede ver sus citas" do
    get appointments_path
    assert_response :success
  end

  test "cliente puede ver el formulario de nueva cita" do
    get new_appointment_path
    assert_response :success
  end

  test "cliente puede crear una cita con datos válidos" do
    assert_difference "Appointment.count", 1 do
      post appointments_path, params: {
        appointment: {
          service_id: @service.id,
          stylist_id: @stylist.id,
          starts_at:  15.days.from_now.change(hour: 11, min: 0)
        }
      }
    end
    assert_redirected_to appointments_path
    follow_redirect!
    assert_response :success
  end

  test "cliente puede cancelar una cita propia" do
    apt = appointments(:cita_pendiente)
    post cancel_appointment_path(apt)
    assert_equal "cancelled", apt.reload.status
    assert_redirected_to appointments_path
  end

  test "la cita recién creada aparece en la lista" do
    post appointments_path, params: {
      appointment: {
        service_id: @service.id,
        stylist_id: @stylist.id,
        starts_at:  20.days.from_now.change(hour: 14, min: 0)
      }
    }
    get appointments_path
    assert_response :success
  end
end
