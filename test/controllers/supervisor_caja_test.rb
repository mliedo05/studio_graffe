require "test_helper"

class SupervisorCajaTest < ActionDispatch::IntegrationTest
  # ── Acceso ────────────────────────────────────────────────────────

  test "usuario no autenticado es redirigido al login" do
    get supervisor_caja_path
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede acceder a caja" do
    sign_in_as(users(:cliente))
    get supervisor_caja_path
    assert_redirected_to root_path
  end

  test "estilista no puede acceder a caja" do
    sign_in_as(users(:valentina))
    get supervisor_caja_path
    assert_redirected_to root_path
  end

  test "admin puede acceder a caja" do
    sign_in_as(users(:admin))
    get supervisor_caja_path
    assert_response :success
  end

  # ── Períodos ──────────────────────────────────────────────────────

  test "caja responde con período por defecto (month)" do
    sign_in_as(users(:admin))
    get supervisor_caja_path
    assert_response :success
  end

  test "caja responde con período today" do
    sign_in_as(users(:admin))
    get supervisor_caja_path(period: "today")
    assert_response :success
  end

  test "caja responde con período week" do
    sign_in_as(users(:admin))
    get supervisor_caja_path(period: "week")
    assert_response :success
  end

  test "caja responde con rango personalizado" do
    sign_in_as(users(:admin))
    get supervisor_caja_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    assert_response :success
  end

  # ── Contenido de la vista ─────────────────────────────────────────

  test "caja muestra secciones clave" do
    sign_in_as(users(:admin))
    get supervisor_caja_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    assert_select "h3", text: /Pendientes de cobro/i
    assert_select "h3", text: /Log de pagos/i
  end

  test "caja muestra atenciones con saldo pendiente" do
    sign_in_as(users(:admin))
    get supervisor_caja_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    # atencion_pendiente y atencion_parcial tienen balance > 0
    assert_match attendances(:atencion_pendiente).number, response.body
  end

  test "caja muestra botón registrar pago para pendientes" do
    sign_in_as(users(:admin))
    get supervisor_caja_path(period: "custom", from: "2026-01-01", to: "2026-01-31")
    assert_match "Registrar pago", response.body
  end

  # ── Registrar pago ────────────────────────────────────────────────

  test "registrar_pago crea un AttendancePayment" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)

    assert_difference "AttendancePayment.count", 1 do
      post supervisor_caja_registrar_pago_path, params: {
        attendance_id:  attendance.id,
        payment_method: "cash",
        amount_cents:   "59500",
        period:         "month"
      }
    end

    assert_redirected_to supervisor_caja_path(period: "month", from: nil, to: nil)
    assert_match "Pago registrado", flash[:notice]
  end

  test "registrar_pago actualiza paid_cents de la atención" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)

    post supervisor_caja_registrar_pago_path, params: {
      attendance_id:  attendance.id,
      payment_method: "transfer",
      amount_cents:   "59500",
      period:         "month"
    }

    attendance.reload
    assert_equal 59500, attendance.paid_cents
  end

  test "registrar_pago con datos inválidos redirige con alert" do
    sign_in_as(users(:admin))
    post supervisor_caja_registrar_pago_path, params: {
      attendance_id:  attendances(:atencion_pendiente).id,
      payment_method: "cash",
      amount_cents:   "0",    # inválido
      period:         "month"
    }
    assert_redirected_to supervisor_caja_path(period: "month", from: nil, to: nil)
    assert flash[:alert].present?
  end

  test "pago tipo pending no suma a paid_cents" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)
    paid_antes = attendance.paid_cents

    post supervisor_caja_registrar_pago_path, params: {
      attendance_id:  attendance.id,
      payment_method: "pending",
      amount_cents:   "59500",
      period:         "month"
    }

    attendance.reload
    assert_equal paid_antes, attendance.paid_cents
  end
end
