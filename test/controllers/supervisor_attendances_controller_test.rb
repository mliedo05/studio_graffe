require "test_helper"

class SupervisorAttendancesControllerTest < ActionDispatch::IntegrationTest
  # ── Acceso ────────────────────────────────────────────────────────

  test "usuario no autenticado es redirigido al login" do
    delete supervisor_attendance_path(attendances(:atencion_cerrada))
    assert_redirected_to new_user_session_path
  end

  test "cliente no puede eliminar atenciones" do
    sign_in_as(users(:cliente))
    delete supervisor_attendance_path(attendances(:atencion_cerrada))
    assert_redirected_to root_path
  end

  # ── destroy ──────────────────────────────────────────────────────

  test "supervisor puede eliminar una atención" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_pendiente)
    assert_difference "Attendance.count", -1 do
      delete supervisor_attendance_path(attendance)
    end
    assert_redirected_to supervisor_attendances_path
    assert_match "eliminada", flash[:notice]
  end

  test "eliminar atención restaura stock del producto vendido" do
    sign_in_as(users(:admin))
    product = products(:shampoo_wella)
    before  = product.stock_quantity

    attendance = Attendance.create!(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client:        users(:cliente),
      status:        "open"
    )
    attendance.attendance_items.create!(
      item_type:          "product",
      product:            product,
      stylist:            users(:valentina),
      price_cents:        18990,
      commission_percent: 10
    )

    delete supervisor_attendance_path(attendance)
    assert_equal before + 1, product.reload.stock_quantity
  end

  test "eliminar atención restaura gramos de insumo si stock_deducted = true" do
    sign_in_as(users(:admin))
    insumo = products(:tinte_insumo)
    before = insumo.stock_quantity

    attendance = Attendance.create!(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client:        users(:cliente),
      status:        "closed"
    )
    attendance.attendance_items.create!(
      item_type:           "service",
      service:             services(:corte_damas),
      stylist:             users(:valentina),
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          20,
      stock_deducted:      true
    )

    delete supervisor_attendance_path(attendance)
    assert_equal before + 20, insumo.reload.stock_quantity
  end

  test "eliminar atención destruye sus ítems y pagos en cascada" do
    sign_in_as(users(:admin))
    attendance = attendances(:atencion_cerrada)

    item_ids    = attendance.attendance_items.pluck(:id)
    payment_ids = attendance.attendance_payments.pluck(:id)

    delete supervisor_attendance_path(attendance)

    assert_empty AttendanceItem.where(id: item_ids)
    assert_empty AttendancePayment.where(id: payment_ids)
  end
end
