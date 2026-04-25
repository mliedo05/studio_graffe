require "test_helper"

class CommissionTest < ActiveSupport::TestCase
  test "válido con atributos correctos" do
    commission = Commission.new(
      stylist:      users(:valentina),
      appointment:  appointments(:cita_pendiente),
      amount_cents: 6300,
      percentage:   35,
      status:       "pending"
    )
    assert commission.valid?
  end

  test "inválido con porcentaje mayor a 100" do
    commissions(:comision_confirmada).tap { |c| c.percentage = 101; assert_not c.valid? }
  end

  test "inválido con porcentaje negativo" do
    commissions(:comision_confirmada).tap { |c| c.percentage = -1; assert_not c.valid? }
  end

  test "inválido con status desconocido" do
    commissions(:comision_confirmada).tap { |c| c.status = "weird"; assert_not c.valid? }
  end

  test "inválido con amount_cents negativo" do
    commissions(:comision_confirmada).tap do |c|
      c.amount_cents = -1
      assert_not c.valid?
      assert_includes c.errors[:amount_cents], "must be greater than or equal to 0"
    end
  end

  test "pay! marca la comisión como pagada y registra paid_at" do
    commission = commissions(:comision_confirmada)
    assert_nil commission.paid_at
    commission.pay!
    assert_equal "paid", commission.reload.status
    assert_not_nil commission.paid_at
  end

  test "scope pending filtra solo pendientes" do
    assert_includes Commission.pending, commissions(:comision_confirmada)
  end
end
