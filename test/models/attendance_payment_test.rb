require "test_helper"

class AttendancePaymentTest < ActiveSupport::TestCase
  # ── Validaciones ──────────────────────────────────────────────────

  test "válido con método real" do
    %w[cash transfer card other].each do |method|
      payment = AttendancePayment.new(
        attendance:     attendances(:atencion_cerrada),
        payment_method: method,
        amount_cents:   10000
      )
      assert payment.valid?, "#{method} debería ser válido"
    end
  end

  test "válido con método pending" do
    payment = AttendancePayment.new(
      attendance:     attendances(:atencion_pendiente),
      payment_method: "pending",
      amount_cents:   50000
    )
    assert payment.valid?
  end

  test "inválido con método desconocido" do
    payment = AttendancePayment.new(
      attendance:     attendances(:atencion_cerrada),
      payment_method: "bitcoin",
      amount_cents:   10000
    )
    assert_not payment.valid?
    assert payment.errors[:payment_method].any?
  end

  test "inválido con amount_cents cero" do
    payment = AttendancePayment.new(
      attendance:     attendances(:atencion_cerrada),
      payment_method: "cash",
      amount_cents:   0
    )
    assert_not payment.valid?
  end

  test "inválido con amount_cents negativo" do
    payment = AttendancePayment.new(
      attendance:     attendances(:atencion_cerrada),
      payment_method: "cash",
      amount_cents:   -100
    )
    assert_not payment.valid?
  end

  # ── Constantes ────────────────────────────────────────────────────

  test "METHODS incluye los 5 métodos" do
    assert_includes AttendancePayment::METHODS, "cash"
    assert_includes AttendancePayment::METHODS, "transfer"
    assert_includes AttendancePayment::METHODS, "card"
    assert_includes AttendancePayment::METHODS, "other"
    assert_includes AttendancePayment::METHODS, "pending"
  end

  test "METHOD_LABELS tiene etiqueta para pending" do
    assert_equal "Pendiente de pago", AttendancePayment::METHOD_LABELS["pending"]
  end

  test "METHOD_COLORS tiene color para cada método" do
    AttendancePayment::METHODS.each do |m|
      assert AttendancePayment::METHOD_COLORS.key?(m), "Falta color para #{m}"
    end
  end

  # ── Scopes ────────────────────────────────────────────────────────

  test "scope real excluye pagos pending" do
    real = AttendancePayment.real
    assert real.none? { |p| p.payment_method == "pending" }
  end

  test "scope pending devuelve solo pagos pending" do
    pending_payments = AttendancePayment.pending
    assert pending_payments.all? { |p| p.payment_method == "pending" }
  end

  # ── method_label ──────────────────────────────────────────────────

  test "method_label devuelve etiqueta legible" do
    payment = attendance_payments(:pago_efectivo)
    assert_equal "Efectivo", payment.method_label
  end

  test "method_label para pending" do
    payment = attendance_payments(:pago_pendiente_registrado)
    assert_equal "Pendiente de pago", payment.method_label
  end
end
