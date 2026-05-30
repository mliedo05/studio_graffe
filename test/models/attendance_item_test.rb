require "test_helper"

class AttendanceItemTest < ActiveSupport::TestCase
  # ── Validaciones ──────────────────────────────────────────────────

  test "válido con atributos correctos (servicio)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 40
    )
    assert item.valid?, item.errors.full_messages.inspect
  end

  test "válido con atributos correctos (producto)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      product:            products(:shampoo_wella),
      item_type:          "product",
      price_cents:        18990,
      commission_percent: 10
    )
    assert item.valid?, item.errors.full_messages.inspect
  end

  test "inválido con item_type desconocido" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      item_type:          "gift",
      price_cents:        10000,
      commission_percent: 0
    )
    assert_not item.valid?
    assert item.errors[:item_type].any?
  end

  test "inválido con commission_percent fuera de rango" do
    item = attendance_items(:item_servicio)
    item.commission_percent = 110
    assert_not item.valid?
  end

  test "inválido con price_cents negativo" do
    item = attendance_items(:item_servicio)
    item.price_cents = -1
    assert_not item.valid?
  end

  test "servicio requiere association service presente" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      item_type:          "service",
      price_cents:        10000,
      commission_percent: 0
    )
    assert_not item.valid?
    assert item.errors[:service].any?
  end

  # ── IVA_FACTOR y cálculo de neto ─────────────────────────────────

  test "IVA_FACTOR es 1.19" do
    assert_equal 1.19, AttendanceItem::IVA_FACTOR
  end

  test "net_price_cents calcula precio sin IVA 19%" do
    item = attendance_items(:item_servicio)
    # $119.000 / 1.19 = $100.000
    assert_equal 100000, item.net_price_cents
  end

  test "iva_cents devuelve el IVA incluido en el precio" do
    item = attendance_items(:item_servicio)
    # $119.000 - $100.000 = $19.000
    assert_equal 19000, item.iva_cents
  end

  test "studio_cents devuelve neto menos comisión" do
    item = attendance_items(:item_servicio)
    # neto $100.000 - comisión $40.000 = $60.000
    assert_equal 60000, item.studio_cents
  end

  # ── Cálculo de comisión sobre neto ───────────────────────────────

  test "calculate_commission usa el precio NETO (sin IVA)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 40
    )
    item.valid?   # dispara before_validation
    # neto = 100.000 · 40% = 40.000
    assert_equal 40000, item.commission_cents
  end

  test "comisión 0% resulta en commission_cents 0" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 0
    )
    item.valid?
    assert_equal 0, item.commission_cents
  end

  test "comisión NO se calcula sobre precio bruto (con IVA)" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        119000,
      commission_percent: 40
    )
    item.valid?
    # Si fuera sobre bruto: 119.000 * 40% = 47.600. Debe ser 40.000.
    assert_not_equal 47600, item.commission_cents
    assert_equal     40000, item.commission_cents
  end

  # ── set_description ───────────────────────────────────────────────

  test "set_description auto-llena desde el nombre del servicio" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      price_cents:        10000,
      commission_percent: 0
    )
    item.valid?
    assert_equal "Corte Damas", item.description
  end

  test "set_description no sobreescribe si ya tiene valor" do
    item = AttendanceItem.new(
      attendance:         attendances(:atencion_cerrada),
      stylist:            users(:valentina),
      service:            services(:corte_damas),
      item_type:          "service",
      description:        "Descripción personalizada",
      price_cents:        10000,
      commission_percent: 0
    )
    item.valid?
    assert_equal "Descripción personalizada", item.description
  end

  # ── Helpers item_type ─────────────────────────────────────────────

  test "service? devuelve true para item de tipo service" do
    assert attendance_items(:item_servicio).service?
    assert_not attendance_items(:item_servicio).product?
  end

  test "product? devuelve true para item de tipo product" do
    assert attendance_items(:item_producto).product?
    assert_not attendance_items(:item_producto).service?
  end

  # ── Insumo de salón ───────────────────────────────────────────────

  test "válido con consumed_product y grams_used > 0" do
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          15
    )
    assert item.valid?, item.errors.full_messages.inspect
  end

  test "inválido con grams_used pero sin consumed_product" do
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40,
      grams_used:          10
    )
    assert_not item.valid?
    assert item.errors[:consumed_product].any?
  end

  test "inválido con grams_used <= 0" do
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          0
    )
    assert_not item.valid?
    assert item.errors[:grams_used].any?
  end

  test "uses_insumo? es true cuando hay consumed_product y grams_used > 0" do
    item = AttendanceItem.new(
      consumed_product_id: products(:tinte_insumo).id,
      grams_used:          10
    )
    assert item.uses_insumo?
  end

  test "uses_insumo? es false sin consumed_product" do
    item = attendance_items(:item_servicio)
    assert_not item.uses_insumo?
  end

  # ── calculate_product_cost ────────────────────────────────────────

  test "calculate_product_cost calcula costo correcto en pesos" do
    # tinte_insumo: cost_per_gram_cents = 680
    # 15 gramos × 680 = 10.200
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          15
    )
    item.valid?
    assert_equal 10200, item.product_cost_cents
  end

  test "calculate_product_cost es 0 sin insumo" do
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40
    )
    item.valid?
    assert_equal 0, item.product_cost_cents
  end

  # ── gross_commission_cents / commissionable_cents ─────────────────

  test "gross_commission_cents es neto × %" do
    # $119.000 → neto $100.000 · 40% = $40.000
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40
    )
    item.valid?
    assert_equal 40000, item.gross_commission_cents
  end

  test "commissionable_cents descuenta costo de insumo de la comisión" do
    # $119.000 → neto $100.000 · 40% = $40.000 − insumo $10.200 = $29.800
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          15
    )
    item.valid?
    assert_equal 29800, item.commissionable_cents
  end

  test "commissionable_cents nunca es negativo (mínimo 0)" do
    # Insumo muy caro que supera la comisión bruta
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         11900,          # neto $10.000 · 10% = $1.000 comisión bruta
      commission_percent:  10,
      consumed_product:    products(:tinte_insumo),
      grams_used:          100             # 100 gr × 680 = $68.000 > $1.000
    )
    item.valid?
    assert_equal 0, item.commissionable_cents
  end

  test "commission_cents guarda el commissionable_cents calculado" do
    # Verifica que el before_validation asigna correctamente
    item = AttendanceItem.new(
      attendance:          attendances(:atencion_cerrada),
      stylist:             users(:valentina),
      service:             services(:corte_damas),
      item_type:           "service",
      price_cents:         119000,
      commission_percent:  40,
      consumed_product:    products(:tinte_insumo),
      grams_used:          15
    )
    item.valid?
    assert_equal item.commissionable_cents, item.commission_cents
  end
end
