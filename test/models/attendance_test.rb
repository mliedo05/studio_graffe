require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  # ── Validaciones ──────────────────────────────────────────────────

  test "válida con atributos correctos" do
    a = Attendance.new(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client:        users(:cliente),
      status:        "open"
    )
    assert a.valid?, a.errors.full_messages.inspect
  end

  test "válida con client_name cuando no hay client" do
    a = Attendance.new(
      attended_on:   Date.current,
      registered_by: users(:admin),
      client_name:   "Clienta Walk-in",
      status:        "open"
    )
    assert a.valid?
  end

  test "inválida sin attended_on" do
    a = attendances(:atencion_cerrada)
    a.attended_on = nil
    assert_not a.valid?
  end

  test "inválida con status desconocido" do
    a = attendances(:atencion_cerrada)
    a.status = "pagada"
    assert_not a.valid?
  end

  test "inválida sin client ni client_name" do
    a = Attendance.new(
      attended_on:   Date.current,
      registered_by: users(:admin),
      status:        "open"
    )
    assert_not a.valid?
    assert a.errors[:client_name].any?
  end

  # ── balance_cents / pending_cents ─────────────────────────────────

  test "balance_cents es total menos paid" do
    a = attendances(:atencion_pendiente)
    assert_equal a.total_cents - a.paid_cents, a.balance_cents
  end

  test "balance_cents es 0 cuando está totalmente pagada" do
    a = attendances(:atencion_cerrada)
    assert_equal 0, a.balance_cents
  end

  test "pending_cents alias de balance_cents" do
    a = attendances(:atencion_parcial)
    assert_equal a.balance_cents, a.pending_cents
  end

  # ── fully_paid? / partially_paid? ────────────────────────────────

  test "fully_paid? es true cuando balance es 0" do
    a = attendances(:atencion_cerrada)
    assert a.fully_paid?
  end

  test "fully_paid? es false cuando hay balance pendiente" do
    a = attendances(:atencion_pendiente)
    assert_not a.fully_paid?
  end

  test "partially_paid? es true cuando hay pago parcial" do
    a = attendances(:atencion_parcial)
    assert a.partially_paid?
  end

  test "partially_paid? es false cuando no se ha cobrado nada" do
    a = attendances(:atencion_pendiente)
    assert_not a.partially_paid?
  end

  # ── recalculate! excluye pagos pending ───────────────────────────

  test "recalculate! no cuenta los pagos pending en paid_cents" do
    a = attendances(:atencion_parcial)
    a.recalculate!
    a.reload
    # Solo pago_parcial ($20.000 card) cuenta; pago_pendiente_registrado ($25.000 pending) NO
    assert_equal 20000, a.paid_cents
  end

  test "recalculate! actualiza total_cents desde los ítems" do
    a = attendances(:atencion_cerrada)
    a.recalculate!
    a.reload
    expected = a.attendance_items.sum(:price_cents)
    assert_equal expected, a.total_cents
  end

  # ── display_client_name ───────────────────────────────────────────

  test "display_client_name muestra nombre del cliente asociado" do
    a = attendances(:atencion_cerrada)
    assert_equal users(:cliente).full_name, a.display_client_name
  end

  test "display_client_name usa client_name cuando no hay cliente asociado" do
    a = attendances(:atencion_este_mes)
    assert_equal "Clienta Walk-in", a.display_client_name
  end

  # ── total_commission_cents ────────────────────────────────────────

  test "total_commission_cents suma comisiones de todos los ítems" do
    a = attendances(:atencion_cerrada)
    expected = a.attendance_items.sum(:commission_cents)
    assert_equal expected, a.total_commission_cents
  end

  # ── scope ordered ────────────────────────────────────────────────

  test "scope ordered devuelve por fecha desc" do
    dates = Attendance.ordered.pluck(:attended_on)
    assert_equal dates.sort.reverse, dates
  end
end
