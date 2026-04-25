require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  # GET /citas
  test "GET /citas redirige a login si no está autenticado" do
    get appointments_path
    assert_redirected_to new_user_session_path
  end

  test "GET /citas devuelve 200 para usuario autenticado" do
    sign_in_as users(:cliente)
    get appointments_path
    assert_response :success
  end

  # GET /citas/new
  test "GET /citas/new redirige a login si no está autenticado" do
    get new_appointment_path
    assert_redirected_to new_user_session_path
  end

  test "GET /citas/new devuelve 200 para usuario autenticado" do
    sign_in_as users(:cliente)
    get new_appointment_path
    assert_response :success
  end

  # POST /citas
  test "POST /citas crea cita válida y redirige" do
    sign_in_as users(:cliente)

    assert_difference "Appointment.count", 1 do
      post appointments_path, params: {
        appointment: {
          service_id:  services(:corte_damas).id,
          stylist_id:  users(:valentina).id,
          starts_at:   10.days.from_now.change(hour: 10, min: 0)
        }
      }
    end
    assert_redirected_to appointments_path
  end

  test "POST /citas con parámetros inválidos no crea la cita" do
    sign_in_as users(:cliente)

    assert_no_difference "Appointment.count" do
      post appointments_path, params: {
        appointment: {
          service_id: services(:corte_damas).id,
          stylist_id: users(:valentina).id,
          starts_at:  nil
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # GET /citas/:id
  test "GET /citas/:id devuelve 200 para cita del usuario" do
    sign_in_as users(:cliente)
    get appointment_path(appointments(:cita_pendiente))
    assert_response :success
  end

  # POST /citas/:id/cancel
  test "POST /citas/:id/cancel cancela la cita" do
    sign_in_as users(:cliente)
    post cancel_appointment_path(appointments(:cita_pendiente))
    assert_equal "cancelled", appointments(:cita_pendiente).reload.status
    assert_redirected_to appointments_path
  end
end
